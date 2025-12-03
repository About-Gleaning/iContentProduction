//
//  SettingsView.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsService.shared
    
    var body: some View {
        Form {
            Section(header: Text("AI 配置")) {
                TextField("Qwen API 密钥", text: $settings.apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("从阿里云 DashScope 控制台获取你的 API 密钥。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("存储")) {
                TextField("内容存储路径", text: $settings.storagePath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("选择文件夹") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK {
                        settings.storagePath = panel.url?.path ?? ""
                    }
                }
            }
        }
        .padding()
        .frame(width: 500, height: 300)
        .navigationTitle("设置")
    }
}
