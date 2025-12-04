//
//  ContentModels.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import Foundation
import SwiftData

enum ContentType: String, Codable, CaseIterable, Identifiable {
    case xiaohongshu = "小红书内容"
    case videoScript = "视频脚本"
    case socialPost = "社交媒体帖子"
    case audioPodcast = "音频播客"
    
    var id: String { self.rawValue }
}

struct Chapter: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var summary: String
    var keyPoints: [String]
    
    // 定义编码键
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case keyPoints
    }
    
    // 自定义解码，如果JSON中没有id则自动生成
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.keyPoints = (try? container.decode([String].self, forKey: .keyPoints)) ?? []
    }
    
    // 自定义编码
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(summary, forKey: .summary)
        try container.encode(keyPoints, forKey: .keyPoints)
    }
    
    // 普通初始化方法
    init(id: UUID = UUID(), title: String, summary: String, keyPoints: [String] = []) {
        self.id = id
        self.title = title
        self.summary = summary
        self.keyPoints = keyPoints
    }
}

@Model
final class ContentItem {
    var id: UUID
    var urls: [String]
    var contentTypeRaw: String
    var chaptersData: Data? // Storing [Chapter] as JSON Data
    var contentBody: String
    var originalContentBody: String? // For storing previous content when regenerating
    var duration: Int // For video script and audio podcast
    var wordCount: Int // For xiaohongshu content
    var peopleCount: Int // For audio podcast
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), urls: [String] = [], contentType: ContentType = .xiaohongshu, chapters: [Chapter] = [], contentBody: String = "", duration: Int = 12, wordCount: Int = 500, peopleCount: Int = 2) {
        self.id = id
        self.urls = urls
        self.contentTypeRaw = contentType.rawValue
        self.contentBody = contentBody
        self.originalContentBody = nil
        self.duration = duration
        self.wordCount = wordCount
        self.peopleCount = peopleCount
        self.createdAt = Date()
        self.updatedAt = Date()
        self.chapters = chapters
    }
    
    var contentType: ContentType {
        get { ContentType(rawValue: contentTypeRaw) ?? .xiaohongshu }
        set { contentTypeRaw = newValue.rawValue }
    }
    
    var chapters: [Chapter] {
        get {
            guard let data = chaptersData else { return [] }
            do {
                return try JSONDecoder().decode([Chapter].self, from: data)
            } catch {
                print("Error decoding chapters: \(error)")
                return []
            }
        }
        set {
            do {
                chaptersData = try JSONEncoder().encode(newValue)
            } catch {
                print("Error encoding chapters: \(error)")
                chaptersData = nil
            }
        }
    }
}
