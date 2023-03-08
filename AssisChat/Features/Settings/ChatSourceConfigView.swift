//
//  ChatSourceConfigView.swift
//  AssisChat
//
//  Created by Nooc on 2023-03-06.
//

import SwiftUI

struct ChatSourceConfigView: View {
    @EnvironmentObject private var settingsFeature: SettingsFeature


    var body: some View {
        Content(openAIAPIKey: settingsFeature.configuredOpenAIAPIKey ?? "", openAIDomain: settingsFeature.configuredOpenAIDomain ?? "")
    }
}

private struct Content: View {
    @EnvironmentObject private var essentialFeature: EssentialFeature
    @EnvironmentObject private var settingsFeature: SettingsFeature

    @State var openAIAPIKey: String
    @State var openAIDomain: String

    @State private var validating = false

    var body: some View {
        List {
            Section {
                TextField("sk-XXXXXXX", text: $openAIAPIKey)
            } header: {
                Text("SETTINGS_CHAT_SOURCE_OPENAI_KEY")
            } footer: {
                Text("SETTINGS_CHAT_SOURCE_OPENAI_KEY_HINT")
            }

            Section {
                TextField("api.openai.com", text: $openAIDomain)
            } header: {
                Text("SETTINGS_CHAT_SOURCE_OPENAI_DOMAIN")
            } footer: {
                Text("SETTINGS_CHAT_SOURCE_OPENAI_DOMAIN_HINT")
            }

            Section {
                Button {
                    validateAndSave()
                } label: {
                    HStack {
                        if validating {
                            ProgressView()
                        }

                        Text("SETTINGS_CHAT_SOURCE_VALIDATE_AND_SAVE")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.primary)
                    .colorScheme(.dark)
                }
                .disabled(validating)
                .listRowInsets(EdgeInsets())
            }
        }
    }

    func validateAndSave() -> Void {
        Task {
            if openAIAPIKey.isEmpty {
                essentialFeature.appendAlert(alert: ErrorAlert(message: "SETTINGS_CHAT_SOURCE_NO_API_KEY"))
                return
            }

            let domain = openAIDomain.isEmpty ? nil : openAIDomain

            validating = true

            let saved = await settingsFeature.validateAndConfigOpenAI(apiKey: openAIAPIKey, for: domain)

            validating = false

            if saved {
                essentialFeature.appendAlert(alert: GeneralAlert(title: "SUCCESS", message: "SETTINGS_CHAT_SOURCE_VALIDATE_AND_SAVE_SUCCESS"))
            } else {
                essentialFeature.appendAlert(alert: ErrorAlert(message: "SETTINGS_CHAT_SOURCE_VALIDATE_AND_SAVE_FAILED"))
            }

        }
    }
}

struct ChatSourceConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ChatSourceConfigView()
    }
}