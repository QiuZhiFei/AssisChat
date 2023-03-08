//
//  ChatsView.swift
//  AssisChat
//
//  Created by Nooc on 2023-03-05.
//

import SwiftUI

struct ChatsView: View {
    @EnvironmentObject var chatFeature: ChatFeature

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if !chatFeature.orderedChats.isEmpty {
                List {
                    ForEach(chatFeature.orderedChats) { chat in
                        NavigationLink {
                            ChattingView(chat: chat)
                        } label: {
                            ChatItem(chat: chat)
                        }
                        .swipeActions(edge: .leading, content: {
                            Button {
                                chatFeature.clearMessages(for: chat)
                            } label: {
                                Label("CHAT_CLEAR_MESSAGE", systemImage: "eraser.line.dashed")
                            }
                        })
                        .contextMenu {
                            Button {
                                chatFeature.clearMessages(for: chat)
                            } label: {
                                Label("CHAT_CLEAR_MESSAGE", systemImage: "eraser.line.dashed")
                            }
                            Button(role: .destructive) {
                                chatFeature.deleteChats([chat])
                            } label: {
                                Label("CHAT_DELETE", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: onDelete)
                }
                .listStyle(.plain)
                .animation(.easeOut, value: chatFeature.orderedChats)
            } else {
                VStack {
                    Image(systemName: "eyeglasses")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                        .symbolVariant(.square)
                        .foregroundColor(.secondary)

                    Text("CHATS_EMPTY_HINT")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            ChatCreatingButton()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView()
                        .navigationTitle("SETTINGS")
                } label: {
                    Label("SETTINGS", systemImage: "gearshape")
                }
            }
        }
    }

    func onDelete(_ indices: IndexSet) {
        chatFeature.deleteChats(indices.map({ index in
            chatFeature.orderedChats[index]
        }))
    }
}

private struct ChatItem: View {
    @ObservedObject var chat: Chat

    var body: some View {
        HStack {
            chat.icon.image
                .font(.title2)
                .frame(width: 24, height: 24)
                .padding()
                .background(chat.uiColor)
                .cornerRadius(10)
                .colorScheme(.dark)

            VStack(alignment: .leading, spacing: 5) {
                Text(chat.name)
                Text(chat.systemMessage ?? String(localized: "CHAT_ROLE_PROMPT_BLANK_HINT"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

private struct ChatCreatingButton: View {
    @State var creating = false

    var body: some View {
        Button {
            creating = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .padding()
                .foregroundColor(.primary)
                .background(Color.accentColor)
                .cornerRadius(.infinity)
                .colorScheme(.dark)
                .padding()
        }
        .sheet(isPresented: $creating) {
            NavigationView {
                NewChatView()
                    .navigationTitle("NEW_CHAT_NAME")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsView()
    }
}