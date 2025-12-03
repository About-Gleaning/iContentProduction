//
//  AIChatView.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import SwiftUI

struct AIChatView: View {
    let contextContent: String
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isProcessing = false
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: String // "user" or "ai"
        let content: String
    }
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        HStack {
                            if message.role == "user" {
                                Spacer()
                                Text(message.content)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            } else {
                                Text(message.content)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                TextField("询问此内容...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendMessage()
                    }
                
                Button("发送") {
                    sendMessage()
                }
                .disabled(inputText.isEmpty || isProcessing)
            }
            .padding()
        }
        .navigationTitle("AI 聊天")
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = ChatMessage(role: "user", content: inputText)
        messages.append(userMessage)
        let query = inputText
        inputText = ""
        isProcessing = true
        
        Task {
            do {
                let response = try await AIService.shared.chat(context: contextContent, query: query)
                await MainActor.run {
                    messages.append(ChatMessage(role: "ai", content: response))
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(role: "ai", content: "错误: \(error.localizedDescription)"))
                    isProcessing = false
                }
            }
        }
    }
}
