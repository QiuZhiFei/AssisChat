//
//  EssentialFeature.swift
//  AssisChat
//
//  Created by Nooc on 2023-03-05.
//

import Foundation
import CoreData
import SwiftUI

class EssentialFeature: ObservableObject {
    @Published private var alertQueue: [Alert] = []

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

// MARK: - Alert
extension EssentialFeature {
    var currentAlert: Alert? {
        alertQueue.first
    }

    func dismissCurrentAlert() -> Void {
        alertQueue.removeFirst()
    }

    func appendAlert(alert: Alert) {
        alertQueue.append(alert)
    }
}

protocol Alert {
    var title: LocalizedStringKey { get }
    var message: LocalizedStringKey { get }
}

struct GeneralAlert: Alert {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

struct ErrorAlert: Alert {
    let title = LocalizedStringKey("ERROR")
    let message: LocalizedStringKey
}

// MARK: - Content
extension EssentialFeature {
    struct DataError: LocalizedError {
        let description: String

        var errorDescription: String? {
            description
        }
    }

    func persistData() {
        guard context.hasChanges else { return }

        context.performAndWait {
            do {
                try context.save()
            } catch {
                appendAlert(alert: ErrorAlert(message: LocalizedStringKey(error.localizedDescription)))
            }
        }
    }
}

// MARK: - Network
extension EssentialFeature {
    struct RequestInit {
        enum Method: String {
            case GET = "GET"
            case POST = "POST"
        }

        enum Body {
            case json(data: Encodable)

            var data: Data? {
                switch self {
                case .json(data: let data):
                    return try? JSONEncoder().encode(data)
                }
            }
        }

        let method: Method
        let body: Body?
        let headers: Dictionary<String, String>?
    }

    struct Response<ResponseData: Decodable, ResponseError: Decodable> {
        let response: URLResponse
        let data: ResponseData?
        let error: ResponseError?
    }

    func requestURL<ResponseData: Decodable, ResponseError: Decodable>(urlString: String, init requestInit: RequestInit) async throws -> Response<ResponseData, ResponseError> {
        guard
            let url = URL(string: urlString),
            await UIApplication.shared.canOpenURL(url)
        else {
            throw GeneralError.badURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = requestInit.method.rawValue

        if let body = requestInit.body {
            request.httpBody = body.data
        }

        if let headers = requestInit.headers {
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        let decodedResponseData = try? JSONDecoder().decode(ResponseData.self, from: data)
        let decodedResponseError = try? JSONDecoder().decode(ResponseError.self, from: data)

        return Response(response: response, data: decodedResponseData, error: decodedResponseError)
    }
}

enum GeneralError: Error {
    case badURL
}
