//
//  NewContentView.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import SwiftUI
import SwiftData

// 链接状态枚举
enum LinkStatus: Equatable {
    case pending
    case fetching
    case success
    case failed(String)
    
    var icon: String {
        switch self {
        case .pending: return "circle"
        case .fetching: return "arrow.clockwise"
        case .success: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .fetching: return .blue
        case .success: return .green
        case .failed: return .red
        }
    }
}


// 链接项模型
struct LinkItem: Identifiable, Equatable {
    let id = UUID()
    var url: String
    var status: LinkStatus = .pending
    var content: String = ""
    var isDirectInput: Bool = false // 标记是否为直接输入内容
    

}

struct NewContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentStep = 1
    @State private var linkItems: [LinkItem] = [LinkItem(url: "")]
    @State private var selectedType: ContentType = .videoScript
    @State private var duration: Int = 12
    @State private var length: Int = 500
    @State private var podcastPeopleCount: Int = 2
    @State private var chapterCount: Int? = nil // 可选的章节数量
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    // Data for steps
    @State private var fetchedContent: String = ""
    @State private var chapters: [Chapter] = []
    @State private var contentBody: String = ""
    @State private var refinementInstruction: String = ""
    
    var body: some View {
        VStack {
            // Step Views
            Group {
                if currentStep == 1 {
                    Step1InputView(linkItems: $linkItems, onFetchLink: fetchLinkContent)
                } else if currentStep == 2 {
                    Step2ConfigView(selectedType: $selectedType, duration: $duration, length: $length, podcastPeopleCount: $podcastPeopleCount, chapterCount: $chapterCount)
                } else if currentStep == 3 {
                    Step3ChaptersView(chapters: $chapters)
                } else if currentStep == 4 {
                    Step4ContentView(contentBody: $contentBody, refinementInstruction: $refinementInstruction, selectedType: selectedType, onRefine: refineContent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            
            if isProcessing {
                ProgressView("处理中...")
                    .padding()
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Divider()
            
            // Navigation Buttons
            HStack {
                if currentStep > 1 {
                    Button("上一步") {
                        withAnimation { currentStep -= 1 }
                    }
                    .disabled(isProcessing)
                }
                
                Spacer()
                
                if currentStep == 1 {
                    Button("下一步") {
                        proceedToStep2()
                    }
                    .disabled(!hasValidLinks() || isProcessing)
                } else if currentStep == 2 {
                    Button("下一步") {
                        generateChapters()
                    }
                    .disabled(isProcessing)
                } else if currentStep == 3 {
                    Button("下一步") {
                        generateContentBody()
                    }
                    .disabled(chapters.isEmpty || isProcessing)
                } else if currentStep == 4 {
                    Button("完成") {
                        saveContent()
                    }
                    .disabled(isProcessing)
                }
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    // MARK: - Helper Methods
    
    private func hasValidLinks() -> Bool {
        // Check if there's at least one valid item:
        // - Direct input with content, OR
        // - URL-based item with non-empty URL
        return linkItems.contains { item in
            if item.isDirectInput {
                return !item.content.trimmingCharacters(in: .whitespaces).isEmpty
            } else {
                return !item.url.trimmingCharacters(in: .whitespaces).isEmpty
            }
        }
    }
    
    // MARK: - Actions
    
    private func fetchLinkContent(id: UUID) {
        guard let index = linkItems.firstIndex(where: { $0.id == id }) else { return }
        let url = linkItems[index].url
        guard !url.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Update status to fetching
        linkItems[index].status = .fetching
        // We do not set global isProcessing here to allow user to fetch multiple links or do other things
        
        Task {
            do {
                let content = try await ContentFetcher.shared.fetchContent(from: url)
                await MainActor.run {
                    if let index = linkItems.firstIndex(where: { $0.id == id }) {
                        linkItems[index].content = content
                        linkItems[index].status = .success
                    }
                }
            } catch {
                await MainActor.run {
                    if let index = linkItems.firstIndex(where: { $0.id == id }) {
                        linkItems[index].status = .failed(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func proceedToStep2() {
        // Collect all valid items (both direct input and URL-based)
        let validItems = linkItems.filter { item in
            if item.isDirectInput {
                return !item.content.trimmingCharacters(in: .whitespaces).isEmpty
            } else {
                return !item.url.trimmingCharacters(in: .whitespaces).isEmpty
            }
        }
        
        guard !validItems.isEmpty else { return }
        
        // Check if all URL-based items have successfully fetched content
        let urlBasedItems = validItems.filter { !$0.isDirectInput }
        let pendingLinks = urlBasedItems.filter { $0.status != .success || $0.content.isEmpty }
        if !pendingLinks.isEmpty {
            errorMessage = "请先点击获取内容按钮，确保所有链接都已成功获取内容"
            return
        }
        
        errorMessage = nil
        
        // 构建综合内容
        var combinedContent = ""
        let itemsWithContent = validItems.filter { !$0.content.isEmpty }
        if itemsWithContent.count > 1 {
            combinedContent = "【注意：以下内容来自\(itemsWithContent.count)个不同来源，请综合分析所有来源的内容】\n\n"
        }
        
        for (index, item) in itemsWithContent.enumerated() {
            if item.isDirectInput {
                combinedContent += "=== 来源 \(index + 1): 直接输入 ===\n\n"
            } else {
                combinedContent += "=== 来源 \(index + 1): \(item.url) ===\n\n"
            }
            combinedContent += item.content
            combinedContent += "\n\n"
        }
        
        fetchedContent = combinedContent
        
        // Check for content length limit
        let totalLength = combinedContent.count
        let limit = SettingsService.shared.maxContentLength
        
        if totalLength > limit {
            errorMessage = "当前内容总字数为 \(totalLength) 个字符，超过了 \(limit) 个字符的限制，请修改。"
            return
        }

        withAnimation { currentStep = 2 }
    }
    
    private func generateChapters() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                chapters = try await AIService.shared.generateChapters(
                    from: fetchedContent, 
                    type: selectedType,
                    duration: duration,
                    wordCount: length,
                    peopleCount: podcastPeopleCount,
                    chapterCount: chapterCount
                )
                
                await MainActor.run {
                    isProcessing = false
                    if chapters.isEmpty {
                        errorMessage = "生成章节失败，请重试。"
                    } else {
                        withAnimation { currentStep = 3 }
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "错误: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func generateContentBody() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                contentBody = try await AIService.shared.generateContent(
                    from: fetchedContent, 
                    type: selectedType, 
                    chapters: chapters,
                    duration: duration,
                    wordCount: length,
                    peopleCount: podcastPeopleCount
                )
                
                await MainActor.run {
                    isProcessing = false
                    withAnimation { currentStep = 4 }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "错误: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func refineContent() {
        guard !refinementInstruction.isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let refined = try await AIService.shared.refineContent(original: contentBody, instruction: refinementInstruction)
                await MainActor.run {
                    contentBody = refined
                    refinementInstruction = ""
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "错误: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveContent() {
        let urls = linkItems.filter { !$0.url.trimmingCharacters(in: .whitespaces).isEmpty }.map { $0.url }
        let newItem = ContentItem(
            urls: urls,
            contentType: selectedType,
            chapters: chapters,
            contentBody: contentBody,
            duration: duration,
            wordCount: length,
            peopleCount: podcastPeopleCount
        )
        modelContext.insert(newItem)
        dismiss()
    }
}

// MARK: - Subviews

struct Step1InputView: View {
    @Binding var linkItems: [LinkItem]
    var onFetchLink: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("链接地址")
                    .font(.headline)
                
                Spacer()
                
                Text("已添加 \(linkItems.count) 个链接")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    ForEach($linkItems) { $item in
                        LinkItemRow(
                            item: $item,
                            canDelete: linkItems.count > 1,
                            onDelete: {
                                withAnimation {
                                    let id = $item.wrappedValue.id
                                    linkItems.removeAll(where: { $0.id == id })
                                }
                            },
                            onFetch: {
                                onFetchLink($item.wrappedValue.id)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 300)


            
            // 添加链接和添加内容按钮
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        linkItems.append(LinkItem(url: "", isDirectInput: false))
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("添加链接")
                    }
                    .font(.body)
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation {
                        linkItems.append(LinkItem(url: "", status: .success, content: "", isDirectInput: true))
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("添加内容")
                    }
                    .font(.body)
                    .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            // 提示信息
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 提示")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("• 可以添加多个链接，AI 会综合所有链接的内容进行创作")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• 点击「下一步」后会并行获取所有链接的内容")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• 即使部分链接失败，也可以使用成功获取的内容继续")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
    }
}


struct Step2ConfigView: View {
    @Binding var selectedType: ContentType
    @Binding var duration: Int
    @Binding var length: Int
    @Binding var podcastPeopleCount: Int
    @Binding var chapterCount: Int?
    
    @State private var chapterCountText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                Text("类型：")
                    .font(.headline)
                    .frame(width: 120, alignment: .leading)
                
                Picker("类型", selection: $selectedType) {
                    Text("视频脚本").tag(ContentType.videoScript)
                    Text("小红书内容").tag(ContentType.xiaohongshu)
                    Text("音频播客").tag(ContentType.audioPodcast)
                }
                .pickerStyle(RadioGroupPickerStyle())
            }
            
            // 生成章节数量（通用选项）
            HStack {
                Text("生成章节数量：")
                    .font(.headline)
                    .frame(width: 120, alignment: .leading)
                
                TextField("默认为空，AI自动决定", text: $chapterCountText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
                    .onChange(of: chapterCountText) { _, newValue in
                        if newValue.isEmpty {
                            chapterCount = nil
                        } else if let count = Int(newValue), count > 0 {
                            chapterCount = count
                        }
                    }
                
                Text("章（可选）")
                    .foregroundColor(.secondary)
            }
            
            // 视频脚本显示时长
            if selectedType == .videoScript {
                HStack {
                    Text("时长：")
                        .font(.headline)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("12", value: $duration, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text("分钟")
                }
            }
            
            // 小红书内容显示字数
            if selectedType == .xiaohongshu {
                HStack {
                    Text("字数：")
                        .font(.headline)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("500", value: $length, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                    Text("字")
                }
            }
            
            // 音频播客显示时长和人数
            if selectedType == .audioPodcast {
                HStack {
                    Text("时长：")
                        .font(.headline)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("30", value: $duration, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text("分钟")
                }
                
                HStack {
                    Text("人数：")
                        .font(.headline)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("2", value: $podcastPeopleCount, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text("人")
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct Step3ChaptersView: View {
    @Binding var chapters: [Chapter]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("章节概要")
                .font(.title2)
                .bold()
                .padding(.bottom)
            
            Text("您可以拖拽调整章节顺序，或删除不需要的章节。修改后的章节结构将用于生成最终内容。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            List {
                ForEach($chapters) { $chapter in
                    ChapterRow(chapter: $chapter, onDelete: {
                        if let index = chapters.firstIndex(where: { $0.id == chapter.id }) {
                            withAnimation {
                                _ = chapters.remove(at: index)
                            }
                        }
                    })
                }
                .onMove { indices, newOffset in
                    chapters.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .listStyle(.inset)
            
            if chapters.isEmpty {
                Text("没有章节，请返回上一步重新生成")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
    }
}

struct ChapterRow: View {
    @Binding var chapter: Chapter
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.gray)
                    .font(.title3)
                
                TextField("标题", text: $chapter.title)
                    .font(.headline)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            
            TextEditor(text: $chapter.summary)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(height: 60)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        }
        .padding(.vertical, 8)
    }
}

struct Step4ContentView: View {
    @Binding var contentBody: String
    @Binding var refinementInstruction: String
    var selectedType: ContentType
    var onRefine: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(selectedType == .audioPodcast ? "逐字稿" : "演讲内容")
                .font(.title2)
                .bold()
            
            MarkdownEditor(text: $contentBody, minHeight: 300)
            
            HStack {
                Spacer()
                Button(action: { /* AI Action */ }) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }
            .padding(.top, -60) // Floating effect
            .padding(.trailing)
        }
        .padding()
    }
}

// MARK: - Link Item Row Component

struct LinkItemRow: View {
    @Binding var item: LinkItem
    let canDelete: Bool
    let onDelete: () -> Void
    let onFetch: () -> Void
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if item.isDirectInput {
                // 直接内容输入模式
                HStack(spacing: 12) {
                    // 内容图标
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    
                    // 内容输入框
                    TextEditor(text: $item.content)
                        .frame(minHeight: 80, maxHeight: 200)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .overlay(
                            Group {
                                if item.content.isEmpty {
                                    Text("请输入内容...")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        .allowsHitTesting(false)
                                }
                            }
                        )
                    
                    // 删除按钮
                    if canDelete {
                        Button(action: onDelete) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                // 链接输入模式
                HStack(spacing: 12) {
                    // 状态图标
                    Image(systemName: item.status.icon)
                        .foregroundColor(item.status.color)
                        .frame(width: 20)
                        .rotationEffect(.degrees(item.status == .fetching ? 360 : 0))
                        .animation(item.status == .fetching ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: item.status == .fetching)
                    
                    // 链接输入框
                    TextField("请输入链接地址", text: $item.url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(item.status == .fetching)
                        .onChange(of: item.url) { _, _ in
                            item.status = .pending
                            item.content = ""
                        }
                    
                    // 获取内容/编辑按钮
                    if item.status == .success && !item.content.isEmpty {
                        Button(action: { isEditing = true }) {
                            Text("编辑")
                        }
                        .buttonStyle(.bordered)
                        .sheet(isPresented: $isEditing) {
                            ContentEditorView(content: $item.content, isPresented: $isEditing)
                        }
                    } else {
                        Button(action: onFetch) {
                            Text("获取内容")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(item.url.trimmingCharacters(in: .whitespaces).isEmpty || item.status == .fetching)
                    }
                    
                    // 删除按钮
                    if canDelete {
                        Button(action: onDelete) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 错误信息
                if case .failed(let error) = item.status {
                    Text("错误: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 32)
                }
            }
        }
    }
}

struct ContentEditorView: View {
    @Binding var content: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("编辑内容")
                    .font(.headline)
                
                Spacer()
                
                Text("\(content.count) 字符")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
                
                Button("完成") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            TextEditor(text: $content)
                .font(.body)
                .padding()
                .background(Color.white)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}
