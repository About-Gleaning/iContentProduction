//
//  NewContentView.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import SwiftUI
import SwiftData

struct NewContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentStep = 1
    @State private var urlsText = ""
    @State private var selectedType: ContentType = .videoScript
    @State private var duration: Int = 12
    @State private var length: Int = 500
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    // Data for steps
    @State private var fetchedContent: String = ""
    @State private var chapters: [Chapter] = []
    @State private var contentBody: String = ""
    @State private var refinementInstruction: String = ""
    
    var body: some View {
        VStack {
            // Progress Indicator (Hidden or Minimal as per prototype, but keeping for usability)
            // Prototype doesn't show a clear stepper, but let's keep it simple.
            
            // Step Views
            Group {
                if currentStep == 1 {
                    Step1InputView(urlsText: $urlsText)
                } else if currentStep == 2 {
                    Step2ConfigView(selectedType: $selectedType, duration: $duration, length: $length)
                } else if currentStep == 3 {
                    Step3ChaptersView(chapters: $chapters)
                } else if currentStep == 4 {
                    Step4ContentView(contentBody: $contentBody, refinementInstruction: $refinementInstruction, onRefine: refineContent)
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
                        fetchContent()
                    }
                    .disabled(urlsText.isEmpty || isProcessing)
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
    
    // MARK: - Actions
    
    private func fetchContent() {
        guard !urlsText.isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let urls = urlsText.components(separatedBy: .newlines).filter { !$0.isEmpty }
                var combinedContent = ""
                for url in urls {
                    let content = try await ContentFetcher.shared.fetchContent(from: url)
                    combinedContent += "\n\n--- 来源: \(url) ---\n\n\(content)"
                }
                fetchedContent = combinedContent
                
                await MainActor.run {
                    isProcessing = false
                    withAnimation { currentStep = 2 }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "错误: \(error.localizedDescription)"
                }
            }
        }
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
                    wordCount: length
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
                    wordCount: length
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
        let urls = urlsText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let newItem = ContentItem(
            urls: urls,
            contentType: selectedType,
            chapters: chapters,
            contentBody: contentBody
        )
        modelContext.insert(newItem)
        dismiss()
    }
}

// MARK: - Subviews

struct Step1InputView: View {
    @Binding var urlsText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("链接地址")
                .font(.headline)
            
            // Simulating multiple input fields as per prototype
            // Using TextEditor for simplicity but styling it to look like inputs
            TextEditor(text: $urlsText)
                .font(.body)
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .frame(height: 150)
            
            Button(action: {}) {
                Image(systemName: "plus.circle")
                    .font(.title2)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
}

struct Step2ConfigView: View {
    @Binding var selectedType: ContentType
    @Binding var duration: Int
    @Binding var length: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                Text("类型：")
                    .font(.headline)
                    .frame(width: 80, alignment: .leading)
                
                Picker("类型", selection: $selectedType) {
                    Text("视频脚本").tag(ContentType.videoScript)
                    Text("小红书内容").tag(ContentType.xiaohongshu)
                }
                .pickerStyle(RadioGroupPickerStyle())
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
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach($chapters) { $chapter in
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("标题", text: $chapter.title)
                                .font(.headline)
                                .padding(4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            
                            TextEditor(text: $chapter.summary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                        .padding()
                        .frame(width: 250, height: 300)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
    }
}

struct Step4ContentView: View {
    @Binding var contentBody: String
    @Binding var refinementInstruction: String
    var onRefine: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("演讲内容")
                .font(.title2)
                .bold()
            
            TextEditor(text: $contentBody)
                .font(.body)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            
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
