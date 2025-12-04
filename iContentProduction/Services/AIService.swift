//
//  AIService.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import Foundation

class AIService {
    static let shared = AIService()
    
    private let baseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    
    // 自定义URLSession，超时时间设置为10分钟
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 600 // 10分钟
        configuration.timeoutIntervalForResource = 600 // 10分钟
        return URLSession(configuration: configuration)
    }()
    
    private init() {}
    
    private var apiKey: String {
        SettingsService.shared.apiKey
    }
    
    private var maxContentLength: Int {
        SettingsService.shared.maxContentLength
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double?
    }
    
    struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }
    
    private func performRequest(messages: [ChatMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "AIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key 缺失"])
        }
        
        guard let url = URL(string: baseUrl) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ChatRequest(model: "qwen-plus", messages: messages, temperature: 0.7)
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData
        
        // Debug: Log Request
        print("--- AIService Request ---")
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Request Body: \(jsonString)")
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("--- AIService Error ---")
                print("Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                print("Response: \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        // Debug: Log Response
        if let responseString = String(data: data, encoding: .utf8) {
            print("--- AIService Response ---")
            print("Response: \(responseString)")
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? ""
    }
    
    // MARK: - Public Methods
    
    func generateChapters(from content: String, type: ContentType, duration: Int, wordCount: Int, peopleCount: Int = 2) async throws -> [Chapter] {
        var prompt = ""
        
        // 检测是否为多来源内容
        let isMultiSource = content.contains("【注意：以下内容来自")
        let sourceInstruction = isMultiSource ? "\n\n重要提示：以下内容来自多个不同来源，请综合分析所有来源的信息，提取共同点和互补点，创建一个统一连贯的章节结构。" : ""
        
        switch type {
        case .videoScript:
            prompt = """
            根据以下内容，为时长约\(duration)分钟的视频脚本生成章节列表。
            请根据\(duration)分钟的时长合理规划章节数量和每个章节的内容量。\(sourceInstruction)
            以严格的JSON数组格式返回结果，每个对象包含 'title'、'summary' 和 'keyPoints'（字符串数组）字段。
            不要包含任何markdown格式或额外文本。
            
            内容：
            \(content.prefix(maxContentLength))
            """
        case .xiaohongshu:
            prompt = """
            根据以下内容，为约\(wordCount)字的小红书内容生成章节列表。
            请根据\(wordCount)字的篇幅合理规划章节数量和每个章节的内容量。
            小红书内容应该简洁、有吸引力，适合社交媒体阅读。\(sourceInstruction)
            以严格的JSON数组格式返回结果，每个对象包含 'title'、'summary' 和 'keyPoints'（字符串数组）字段。
            不要包含任何markdown格式或额外文本。
            
            内容：
            \(content.prefix(maxContentLength))
            """
        case .socialPost:
            prompt = """
            根据以下内容，为社交媒体帖子生成章节列表。\(sourceInstruction)
            以严格的JSON数组格式返回结果，每个对象包含 'title'、'summary' 和 'keyPoints'（字符串数组）字段。
            不要包含任何markdown格式或额外文本。
            
            内容：
            \(content.prefix(maxContentLength))
            """
        case .audioPodcast:
            prompt = """
            根据以下内容，为时长约\(duration)分钟、\(peopleCount)人参与的音频播客生成章节大纲。
            请根据\(duration)分钟的时长合理规划话题和讨论流程。\(sourceInstruction)
            以严格的JSON数组格式返回结果，每个对象包含 'title'、'summary' 和 'keyPoints'（字符串数组）字段。
            不要包含任何markdown格式或额外文本。
            
            内容：
            \(content.prefix(maxContentLength))
            """
        }
        
        let messages = [
            ChatMessage(role: "system", content: "你是一位专业的自媒体内容创作者。"),
            ChatMessage(role: "user", content: prompt)
        ]
        
        let responseText = try await performRequest(messages: messages)
        
        // Clean up response if it contains markdown code blocks
        var cleanJson = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除markdown代码块标记
        // 处理 ```json ... ``` 或 ``` ... ``` 格式
        if cleanJson.hasPrefix("```") {
            // 移除开头的 ```json 或 ```
            if cleanJson.hasPrefix("```json") {
                cleanJson = String(cleanJson.dropFirst(7))
            } else if cleanJson.hasPrefix("```") {
                cleanJson = String(cleanJson.dropFirst(3))
            }
            cleanJson = cleanJson.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 移除结尾的 ```
            if cleanJson.hasSuffix("```") {
                cleanJson = String(cleanJson.dropLast(3))
            }
            cleanJson = cleanJson.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard let data = cleanJson.data(using: .utf8) else { return [] }
        
        do {
            return try JSONDecoder().decode([Chapter].self, from: data)
        } catch {
            print("解析章节失败: \(error)")
            print("清理后的JSON: \(cleanJson)")
            // Fallback: try to parse manually or return empty if strict JSON failed
            return []
        }
    }
    
    func generateContent(from content: String, type: ContentType, chapters: [Chapter], duration: Int, wordCount: Int, peopleCount: Int = 2) async throws -> String {
        let chaptersJson = try? JSONEncoder().encode(chapters)
        let chaptersString = String(data: chaptersJson ?? Data(), encoding: .utf8) ?? ""
        
        // 检测是否为多来源内容
        let isMultiSource = content.contains("【注意：以下内容来自")
        let multiSourceNote = isMultiSource ? "\n\n特别注意：原始内容来自多个不同来源，请综合所有来源的信息，融合不同视角和观点，创作出连贯统一、内容丰富的作品。不要简单罗列各个来源的内容，而是要深度整合。" : ""
        
        var prompt = ""
        var systemMessage = ""
        
        switch type {
        case .videoScript:
            systemMessage = "你是一位专业的视频脚本撰写者，擅长综合多个来源的信息创作连贯的内容。"
            prompt = """
            根据原始内容和以下章节大纲，为时长约\(duration)分钟的视频脚本编写完整的内容正文。\(multiSourceNote)
            
            重要要求：
            1. 视频时长为\(duration)分钟，请合理控制内容的节奏和长度
            2. 内容应该适合口语化表达，便于视频演讲
            3. 每个章节的内容量应该与\(duration)分钟的总时长相匹配
            4. 包含适当的过渡和引导语句
            5. 如果有多个来源，请自然地融合不同来源的观点和信息
            
            原始内容：
            \(content.prefix(maxContentLength))
            
            章节：
            \(chaptersString)
            
            请清晰专业地编写视频脚本内容。
            """
        case .xiaohongshu:
            systemMessage = "你是一位专业的小红书内容创作者，擅长综合多个来源的信息创作吸引人的内容。"
            prompt = """
            根据原始内容和以下章节大纲，编写约\(wordCount)字的小红书内容。\(multiSourceNote)
            
            重要要求：
            1. 总字数控制在\(wordCount)字左右（可以有10%的浮动）
            2. 内容要简洁、有吸引力，适合社交媒体阅读
            3. 使用emoji表情增加趣味性
            4. 开头要有吸引力，能够抓住读者注意力
            5. 适当使用分段，提高可读性
            6. 可以包含话题标签
            7. 如果有多个来源，请提炼出最精华和最吸引人的部分
            
            原始内容：
            \(content.prefix(maxContentLength))
            
            章节：
            \(chaptersString)
            
            请编写吸引人的小红书内容。
            """
        case .socialPost:
            systemMessage = "你是一位专业的社交媒体内容创作者，擅长综合多个来源的信息。"
            prompt = """
            根据原始内容和以下章节大纲，编写社交媒体帖子内容。\(multiSourceNote)
            
            原始内容：
            \(content.prefix(maxContentLength))
            
            章节：
            \(chaptersString)
            
            请清晰专业地编写内容。
            """
        case .audioPodcast:
            systemMessage = "你是一位专业的播客制作人，擅长创作引人入胜的对话脚本。"
            prompt = """
            根据原始内容和以下章节大纲，为时长约\(duration)分钟、\(peopleCount)人参与的音频播客创作逐字稿。\(multiSourceNote)
            
            重要要求：
            1. 必须是逐字稿格式，明确标注说话人（如：主持人、嘉宾A、嘉宾B等）。
            2. 参与人数为\(peopleCount)人，请分配合适的角色和对话比例。
            3. 语言风格要自然、口语化，像真实的对话一样，包含语气词和自然的互动。
            4. 内容要有深度，同时保持轻松有趣的氛围。
            5. 总时长控制在\(duration)分钟左右。
            6. 如果有多个来源，请通过对话的形式自然地引入和讨论不同来源的观点。
            
            原始内容：
            \(content.prefix(maxContentLength))
            
            章节：
            \(chaptersString)
            
            请创作精彩的播客逐字稿。
            """
        }
        
        let messages = [
            ChatMessage(role: "system", content: systemMessage),
            ChatMessage(role: "user", content: prompt)
        ]
        
        return try await performRequest(messages: messages)
    }
    
    func refineContent(original: String, instruction: String) async throws -> String {
        let prompt = """
        根据以下指令优化内容：“\(instruction)”
        
        内容：
        \(original)
        """
        
        let messages = [
            ChatMessage(role: "system", content: "你是一位专业的编辑。"),
            ChatMessage(role: "user", content: prompt)
        ]
        
        return try await performRequest(messages: messages)
    }
    
    func chat(context: String, query: String) async throws -> String {
        let messages = [
            ChatMessage(role: "system", content: "你是一个乐于助人的助手。根据提供的上下文回答用户的问题。\n\n上下文：\n\(context.prefix(10000))"),
            ChatMessage(role: "user", content: query)
        ]
        
        return try await performRequest(messages: messages)
    }
    
    func regenerateContent(previousContent: String, chapters: [Chapter], type: ContentType, modificationRequirement: String, duration: Int, wordCount: Int, peopleCount: Int = 2) async throws -> String {
        let chaptersJson = try? JSONEncoder().encode(chapters)
        let chaptersString = String(data: chaptersJson ?? Data(), encoding: .utf8) ?? ""
        
        var prompt = ""
        var systemMessage = ""
        
        switch type {
        case .videoScript:
            systemMessage = "你是一位专业的视频脚本撰写者。"
            prompt = """
            根据用户的修改要求，对以下视频脚本内容进行重新生成。
            
            修改要求：\(modificationRequirement)
            
            原脚本（时长约\(duration)分钟）：
            \(previousContent.prefix(maxContentLength))
            
            章节结构：
            \(chaptersString)
            
            重要要求：
            1. 保持视频时长为\(duration)分钟
            2. 必须严格按照用户的修改要求进行调整
            3. 保持内容的连贯性和专业性
            4. 适合口语化表达，便于视频演讲
            
            请根据修改要求重新生成视频脚本。
            """
        case .xiaohongshu:
            systemMessage = "你是一位专业的小红书内容创作者。"
            prompt = """
            根据用户的修改要求，对以下小红书内容进行重新生成。
            
            修改要求：\(modificationRequirement)
            
            原内容（约\(wordCount)字）：
            \(previousContent.prefix(maxContentLength))
            
            章节结构：
            \(chaptersString)
            
            重要要求：
            1. 总字数控制在\(wordCount)字左右（可以有10%的浮动）
            2. 必须严格按照用户的修改要求进行调整
            3. 保持小红书的风格：简洁、有吸引力
            4. 适当使用emoji表情
            
            请根据修改要求重新生成小红书内容。
            """
        case .socialPost:
            systemMessage = "你是一位专业的社交媒体内容创作者。"
            prompt = """
            根据用户的修改要求，对以下社交媒体帖子内容进行重新生成。
            
            修改要求：\(modificationRequirement)
            
            原内容：
            \(previousContent.prefix(maxContentLength))
            
            章节结构：
            \(chaptersString)
            
            请根据修改要求重新生成社交媒体帖子内容。
            """
        case .audioPodcast:
            systemMessage = "你是一位专业的播客制作人。"
            prompt = """
            根据用户的修改要求，对以下播客逐字稿进行重新生成。
            
            修改要求：\(modificationRequirement)
            
            原逐字稿（时长约\(duration)分钟，\(peopleCount)人参与）：
            \(previousContent.prefix(maxContentLength))
            
            章节结构：
            \(chaptersString)
            
            重要要求：
            1. 保持逐字稿格式，明确标注说话人
            2. 参与人数为\(peopleCount)人
            3. 总时长控制在\(duration)分钟左右
            4. 必须严格按照用户的修改要求进行调整
            5. 保持自然、口语化的对话风格
            
            请根据修改要求重新生成播客逐字稿。
            """
        }
        
        let messages = [
            ChatMessage(role: "system", content: systemMessage),
            ChatMessage(role: "user", content: prompt)
        ]
        
        return try await performRequest(messages: messages)
    }
}
