//
//  MarkdownText.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/05.
//

import SwiftUI

/// A SwiftUI view that renders markdown-formatted text
struct MarkdownText: View {
    let content: String
    var fontSize: CGFloat = 14
    var lineSpacing: CGFloat = 4
    
    var body: some View {
        if let attributedString = parseMarkdownWithLineBreaks(content) {
            Text(attributedString)
                .font(.system(size: fontSize))
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
        } else {
            // Fallback if markdown parsing fails
            Text(content)
                .font(.system(size: fontSize))
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
        }
    }
    
    // 逐行解析 Markdown，手动添加换行
    private func parseMarkdownWithLineBreaks(_ text: String) -> AttributedString? {
        let lines = text.components(separatedBy: "\n")
        var result = AttributedString()
        
        for (index, line) in lines.enumerated() {
            // 对每一行进行 Markdown 解析
            if let lineAttr = try? AttributedString(markdown: line, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                result.append(lineAttr)
            } else {
                result.append(AttributedString(line))
            }
            
            // 添加换行（除了最后一行）
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }
        
        return result
    }
}

/// A ScrollView variant that supports markdown content display
struct MarkdownScrollView: View {
    let content: String
    var fontSize: CGFloat = 14
    var lineSpacing: CGFloat = 4
    var backgroundColor: Color = .clear
    var padding: CGFloat = 16
    
    var body: some View {
        ScrollView {
            if let attributedString = parseMarkdownWithLineBreaks(content) {
                Text(attributedString)
                    .font(.system(size: fontSize))
                    .lineSpacing(lineSpacing)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(padding)
            } else {
                // Fallback if markdown parsing fails
                Text(content)
                    .font(.system(size: fontSize))
                    .lineSpacing(lineSpacing)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(padding)
            }
        }
        .background(backgroundColor)
    }
    
    // 逐行解析 Markdown，手动添加换行
    private func parseMarkdownWithLineBreaks(_ text: String) -> AttributedString? {
        let lines = text.components(separatedBy: "\n")
        var result = AttributedString()
        
        for (index, line) in lines.enumerated() {
            // 对每一行进行 Markdown 解析
            if let lineAttr = try? AttributedString(markdown: line, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                result.append(lineAttr)
            } else {
                result.append(AttributedString(line))
            }
            
            // 添加换行（除了最后一行）
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }
        
        return result
    }
}

/// A TextEditor variant that supports markdown preview
struct MarkdownEditor: View {
    @Binding var text: String
    @State private var showPreview = false
    var minHeight: CGFloat = 200
    
    var body: some View {
        VStack(spacing: 0) {
            // Toggle bar
            HStack {
                Spacer()
                
                Picker("", selection: $showPreview) {
                    Text("编辑").tag(false)
                    Text("预览").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .background(Color.gray.opacity(0.1))
            
            // Content area
            if showPreview {
                MarkdownScrollView(content: text)
                    .frame(minHeight: minHeight)
                    .background(Color.white)
            } else {
                TextEditor(text: $text)
                    .font(.body)
                    .frame(minHeight: minHeight)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
