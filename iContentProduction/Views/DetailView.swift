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
                    Text("演讲内容")
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
            // Floating AI Chat Button
            Button(action: { showingChat = true }) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
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
