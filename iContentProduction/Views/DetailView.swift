//
//  DetailView.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import SwiftUI

struct DetailView: View {
    @Bindable var item: ContentItem
    @State private var isEditing = false
    @State private var showingChat = false
    @State private var showingRegenerate = false
    @State private var modificationRequirement = ""
    @State private var isRegenerating = false
    @State private var regenerationError: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Info
                HStack {
                    Text(item.chapters.first?.title ?? "无标题")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                    
                    Button("编辑") {
                        isEditing = true
                    }
                    .buttonStyle(.bordered)
                }
                
                // Source Links Section
                if !item.urls.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("来源链接")
                            .font(.title2)
                            .bold()
                        
                        ForEach(item.urls, id: \.self) { urlString in
                            if let url = URL(string: urlString) {
                                Link(urlString, destination: url)
                                    .font(.body)
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            } else {
                                Text(urlString)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                // Chapter Summary Section
                VStack(alignment: .leading) {
                    Text("章节概要")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 5)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(item.chapters) { chapter in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(chapter.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    
                                    Text(chapter.summary)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(8)
                                    
                                    Spacer()
                                }
                                .padding()
                                .frame(width: 200, height: 250)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                Divider()
                
                // Content Body Section
                VStack(alignment: .leading) {
                    Text(item.contentType == .audioPodcast ? "逐字稿" : "演讲内容")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 5)
                    
                    Text(item.contentBody)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor)) // Use system background
        .overlay(
            // Floating Buttons Stack
            VStack(spacing: 16) {
                // AI Regenerate Button
                Button(action: { showingRegenerate = true }) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.purple)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                
                // AI Chat Button
                Button(action: { showingChat = true }) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }
            .padding()
            , alignment: .bottomTrailing
        )
        .sheet(isPresented: $isEditing) {
            EditContentView(item: item)
        }
        .sheet(isPresented: $showingChat) {
            NavigationView {
                AIChatView(contextContent: item.contentBody)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") { showingChat = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingRegenerate) {
            AIRegenerateView(
                item: item,
                modificationRequirement: $modificationRequirement,
                isRegenerating: $isRegenerating,
                regenerationError: $regenerationError,
                isPresented: $showingRegenerate
            )
        }
    }
}

struct EditContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ContentItem
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("信息")) {
                    Picker("类型", selection: $item.contentType) {
                        ForEach(ContentType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("章节")) {
                    List {
                        ForEach($item.chapters) { $chapter in
                            VStack(alignment: .leading) {
                                TextField("标题", text: $chapter.title)
                                TextField("概要", text: $chapter.summary)
                            }
                        }
                        .onMove { indices, newOffset in
                            item.chapters.move(fromOffsets: indices, toOffset: newOffset)
                        }
                    }
                }
                
                Section(header: Text("内容正文")) {
                    TextEditor(text: $item.contentBody)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("编辑内容")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        item.updatedAt = Date()
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// MARK: - AI Regenerate View

struct AIRegenerateView: View {
    @Bindable var item: ContentItem
    @Binding var modificationRequirement: String
    @Binding var isRegenerating: Bool
    @Binding var regenerationError: String?
    @Binding var isPresented: Bool
    
    @State private var generatedContent: String? = nil
    @State private var showComparison = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if generatedContent == nil {
                    // Input Phase
                    VStack(spacing: 20) {
                        // Title and Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI 内容重新生成")
                                .font(.title2)
                                .bold()
                            
                            Text("告诉 AI 你希望如何修改内容，AI 将基于当前内容和你的要求重新生成。")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Modification Requirement Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("修改要求")
                                .font(.headline)
                            
                            TextEditor(text: $modificationRequirement)
                                .font(.body)
                                .frame(minHeight: 150)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                .overlay(
                                    Group {
                                        if modificationRequirement.isEmpty {
                                            Text("例如：\n• 请使内容更加简洁\n• 增加更多实际案例\n• 改成更正式的语气\n• 增加幽默元素")
                                                .foregroundColor(.gray.opacity(0.6))
                                                .padding(.top, 8)
                                                .padding(.leading, 5)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                )
                        }
                        
                        // Error Message
                        if let error = regenerationError {
                            Text("错误: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Generate Button
                        if isRegenerating {
                            ProgressView("正在重新生成内容...")
                                .padding()
                        } else {
                            Button(action: regenerateContent) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("重新生成内容")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(modificationRequirement.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .disabled(modificationRequirement.trimmingCharacters(in: .whitespaces).isEmpty)
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                    }
                } else {
                    // Preview Phase
                    VStack(spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("预览生成的内容")
                                .font(.title2)
                                .bold()
                            
                            Text("请查看AI生成的新内容，确认后点击’应用‘按钮更新，或点击‘重新生成’再次生成。")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Toggle between comparison and single view
                        Picker("查看模式", selection: $showComparison) {
                            Text("仅新内容").tag(false)
                            Text("对比查看").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Content Display
                        ScrollView {
                            if showComparison {
                                // Comparison View
                                HStack(alignment: .top, spacing: 16) {
                                    // Original Content
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("原内容")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        
                                        Text(item.contentBody)
                                            .font(.body)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    Divider()
                                    
                                    // New Content
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("新内容")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        
                                        Text(generatedContent ?? "")
                                            .font(.body)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding()
                            } else {
                                // Single View - New Content Only
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("新内容")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    
                                    Text(generatedContent ?? "")
                                        .font(.body)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                }
                                .padding()
                            }
                        }
                        .frame(maxHeight: .infinity)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            // Regenerate Button
                            Button(action: {
                                generatedContent = nil
                                regenerationError = nil
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("重新生成")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            // Apply Button
                            Button(action: applyGeneratedContent) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("应用")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
            .navigationTitle("重新生成内容")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        isPresented = false
                        modificationRequirement = ""
                        regenerationError = nil
                        generatedContent = nil
                        showComparison = false
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
    }
    
    private func regenerateContent() {
        regenerationError = nil
        isRegenerating = true
        
        Task {
            do {
                let newContent = try await AIService.shared.regenerateContent(
                    previousContent: item.contentBody,
                    chapters: item.chapters,
                    type: item.contentType,
                    modificationRequirement: modificationRequirement,
                    duration: item.duration,
                    wordCount: item.wordCount,
                    peopleCount: item.peopleCount
                )
                
                await MainActor.run {
                    isRegenerating = false
                    generatedContent = newContent
                }
            } catch {
                await MainActor.run {
                    isRegenerating = false
                    regenerationError = error.localizedDescription
                }
            }
        }
    }
    
    private func applyGeneratedContent() {
        guard let newContent = generatedContent else { return }
        
        // Store current content as original
        item.originalContentBody = item.contentBody
        // Update with new content
        item.contentBody = newContent
        item.updatedAt = Date()
        
        // Close the sheet
        isPresented = false
        modificationRequirement = ""
        generatedContent = nil
        showComparison = false
    }
}
