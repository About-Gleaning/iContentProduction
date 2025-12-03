//
//  HomeView.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentItem.createdAt, order: .reverse) private var items: [ContentItem]
    
    @State private var showingNewContentSheet = false
    @State private var showingSettingsSheet = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(items) { item in
                            NavigationLink {
                                DetailView(item: item)
                            } label: {
                                ContentCard(item: item)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                
                // Floating Action Buttons
                HStack {
                    Spacer()
                    
                    Button(action: { /* AI Action */ }) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.black)
                            .frame(width: 50, height: 50)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("我的内容")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewContentSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingSettingsSheet = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewContentSheet) {
            NewContentView()
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

struct ContentCard: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.chapters.first?.title ?? "无标题")
                .font(.headline)
                .lineLimit(1)
            
            Text(item.contentBody)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            HStack {
                Text(item.contentTypeRaw)
                    .font(.caption2)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(item.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(height: 150)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }


}
