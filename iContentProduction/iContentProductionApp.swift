//
//  iContentProductionApp.swift
//  iContentProduction
//
//  Created by 刘瑞 on 2025/12/2.
//

import SwiftUI
import SwiftData

@main
struct iContentProductionApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            ContentItem.self,
        ])
        
        // Enable auto migration for schema changes
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            // If migration fails, try to create a fresh container
            print("Migration error: \(error)")
            print("Attempting to create fresh container...")
            
            // For development: delete old data and create fresh container
            let freshConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            do {
                return try ModelContainer(for: schema, configurations: [freshConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
