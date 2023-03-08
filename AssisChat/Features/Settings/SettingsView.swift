//
//  SettingsView.swift
//  AssisChat
//
//  Created by Nooc on 2023-03-06.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                VStack {
                    Image("Icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(20)
                    Text("AssisChat")
                        .padding(.top)
                    Text("APP_SLOGAN")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)

            Section("SETTINGS_CHAT") {
                NavigationLink {
                    ChatSourceConfigView()
                        .navigationTitle("SETTINGS_CHAT_SOURCE")
                } label: {
                    Label("SETTINGS_CHAT_SOURCE", systemImage: "globe.asia.australia")
                }
            }

            Section("SETTINGS_THEME") {
                NavigationLink {
                    ColorSchemeSelector()
                        .navigationTitle("SETTINGS_COLOR_SCHEME")
                } label: {
                    Label {
                        Text("SETTINGS_COLOR_SCHEME")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "die.face.5")
                            .foregroundColor(.appOrange)
                    }
                }

                NavigationLink {
                    TintSelector()
                        .navigationTitle("SETTINGS_TINT")
                } label: {
                    Label {
                        Text("SETTINGS_TINT")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "paintbrush.pointed")
                            .foregroundColor(.appIndigo)
                    }
                }
            }

            Section("SETTINGS_ABOUT") {
                Button {
                    openURL(URL(string: "https://twitter.com/noobnooc")!)
                } label: {
                    Label {
                        Text("Twitter")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "bird")
                            .foregroundColor(.appBlue)
                    }
                }

                Button {
                    openURL(URL(string: "mailto:app@nooc.ink")!)
                } label: {
                    Label {
                        Text("SETTINGS_FEEDBACK")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "envelope")
                            .foregroundColor(.appRed)
                    }
                }
            }

            CopyrightView(detailed: true)
                .listRowBackground(Color.clear)
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
