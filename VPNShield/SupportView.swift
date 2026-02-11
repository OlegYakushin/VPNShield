//
//  SupportView.swift
//  VPNShield
//
//  Created by Oleg Yakushin on 14/7/25.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct SupportView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Здравствуйте! Чем можем вам помочь?", isUser: false)
    ]
    @State private var inputText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { scroll in
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(messages) { msg in
                                HStack {
                                    if msg.isUser { Spacer() }
                                    Text(msg.text)
                                        .padding()
                                        .background(msg.isUser ? Color.blue : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    if !msg.isUser { Spacer() }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            scroll.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                HStack {
                    TextField("Сообщение...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Поддержка", displayMode: .inline)
        }
    }

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(text: trimmed, isUser: true))
        inputText = ""
        // Handle sending to backend and append response
    }
}


#Preview {
    SupportView()
}
