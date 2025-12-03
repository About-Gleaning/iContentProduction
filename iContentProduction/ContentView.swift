//
//  ContentView.swift
//  iContentProduction
//
//  Created by 刘瑞 on 2025/12/2.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
