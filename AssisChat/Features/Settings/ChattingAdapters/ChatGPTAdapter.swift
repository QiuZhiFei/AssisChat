//
//  ChatGPTAdapter.swift
//  AssisChat
//
//  Created by Nooc on 2023-03-06.
//

import Foundation
import LDSwiftEventSource
import Combine

class ChatGPTAdapter {
    struct Config {
        let domain: String?
        let apiKey: String
    }

    let essentialFeature: EssentialFeature
    let config: Config

    init(essentialFeature: EssentialFeature, config: Config) {
        self.essentialFeature = essentialFeature
        self.config = config
    }
}

extension ChatGPTAdapter: ChattingAdapter {
    func sendMessageWithStream(message: Message, receivingMessage: Message) async throws {
        try await requestStream(messages: retrieveGPTMessages(message: message), for: receivingMessage)
    }

    func sendMessage(message: Message) async throws -> [PlainMessage] {
        guard let chat = message.chat else { return [] }

        return try await request(messages: retrieveGPTMessages(message: message), temperature: chat.temperature.rawValue).map { gptMessage in
            gptMessage.toPlainMessage(for: chat)
        }
    }

    func validateConfig() async -> Bool {
        do {
            let result = try await request(messages: [.init(role: .user, content: "Test")], temperature: 1)

            return !result.isEmpty
        } catch {
            return false
        }
    }

    func requestStream(messages: [ChatGPTMessage], for message: Message) async throws {
        guard let chat = message.chat else { return }

        let handler = Handler()
        var config = EventSource.Config(handler: handler, url: URL(string: "https://\(config.domain ?? "api.openai.com")/v1/chat/completions")!)

        config.method = "POST"
        config.headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(self.config.apiKey)"
        ]
        config.body = try? JSONEncoder().encode(RequestBody(
            model: .gpt35turbo,
            messages: messages,
            temperature: chat.temperature.rawValue,
            stream: true)
        )

        var cancelable: AnyCancellable?
        let eventSource = EventSource(config: config)

        try await withCheckedThrowingContinuation { continuation in
            cancelable = handler.publisher.sink { completion in
                eventSource.stop()

                switch completion {
                case .finished: continuation.resume()
                case .failure(let error):
                    continuation.resume(with: .failure(error))
                }
            } receiveValue: { value in
                message.appendReceivingSlice(slice: value)
                self.essentialFeature.persistData()
            }

            eventSource.start()
        }
    }

    func request(messages: [ChatGPTMessage], temperature: Float) async throws -> [ChatGPTMessage] {
        let response: EssentialFeature.Response<ResponseBody, ResponseError> = try await essentialFeature.requestURL(
            urlString: "https://\(config.domain ?? "api.openai.com")/v1/chat/completions",
            init: .init(
                method: .POST,
                body: .json(data: RequestBody(
                    model: .gpt35turbo,
                    messages: messages,
                    temperature: temperature,
                    stream: false)),
                headers: [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer \(config.apiKey)"
                ]))

        guard let responseData = response.data else {
            let errorMessage = response.error?.error.message ?? "Unknown Error"

            throw ChattingError.sending(message: errorMessage)
        }

        return responseData.choices.map { choice in
            choice.message
        }
    }

    private func retrieveGPTMessages(message: Message) -> [ChatGPTMessage] {
        guard let chat = message.chat else { return [] }

        let systemMessages = chat.systemMessage != nil ? [ChatGPTMessage(role: .system, content: chat.systemMessage!)] : []

        var gptMessages: [ChatGPTMessage]

        if chat.isolated {
            gptMessages = systemMessages + [ChatGPTMessage.fromMessage(message: message)]
        } else {
            gptMessages = systemMessages + (chat.messages + [message]).map({ message in
                ChatGPTMessage.fromMessage(message: message)
            })
        }

        return gptMessages
    }

    struct RequestBody: Encodable {
        let model: Model
        let messages: [ChatGPTMessage]
        let temperature: Float
        let stream: Bool

        enum Model: String, Encodable {
            case gpt35turbo = "gpt-3.5-turbo"
        }

    }

    struct ResponseBody: Decodable {
        let id: String
        let object: String
        let created: Int
        let choices: [Choice]
        let usage: Usage

        struct Choice: Decodable {
            let index: Int
            let message: ChatGPTMessage
            let finish_reason: String?
        }

        struct Usage: Decodable {
            let prompt_tokens: Int
            let completion_tokens: Int
            let total_tokens: Int
        }
    }

    struct ResponseError: Decodable {
        struct Error: Decodable {
            let message: String?
            let type: String
        }

        let error: Error;
    }

    struct ChatGPTMessage: Codable {
        let role: Role
        let content: String

        enum Role: String, Codable {
            case system = "system"
            case user = "user"
            case assistant = "assistant"
        }

        func toPlainMessage(for chat: Chat) -> PlainMessage {
            var role: Message.Role

            switch(self.role) {
            case .system: role = .system
            case .user: role = .user
            case .assistant: role = .assistant
            }

            return PlainMessage(chat: chat, role: role, content: content, processedContent: nil)
        }

        static func fromMessage(message: Message) -> ChatGPTMessage {
            var role: Role

            switch(message.role) {
            case .system: role = .system
            case .user: role = .user
            case .assistant: role = .assistant
            }

            return ChatGPTMessage(role: role, content: message.processedContent ?? message.content ?? "")
        }
    }
}

private struct Handler: EventHandler {
    struct MessageData: Decodable {
        let choices: [Choice]

        struct Choice: Decodable {
            let delta: Delta

            struct Delta: Decodable {
                let content: String
            }
        }
    }

    let publisher = PassthroughSubject<String, Error>()

    func onOpened() {
    }

    func onClosed() {
        publisher.send(completion: .finished)
    }

    func onComment(comment: String) {
    }

    func onError(error: Error) {
        publisher.send(completion: .failure(error))
    }

    func onMessage(eventType: String, messageEvent: MessageEvent) {
        guard messageEvent.data != "[DONE]" else {
            publisher.send(completion: .finished)
            return
        }

        guard
            let data = messageEvent.data.data(using: .utf8),
            let decodedData = try? JSONDecoder().decode(MessageData.self, from: data),
            let content = decodedData.choices.first?.delta.content
        else {
            return
        }

        publisher.send(content)
    }
}