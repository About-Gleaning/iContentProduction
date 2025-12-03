//
//  SettingsService.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import Foundation
import SwiftUI

class SettingsService: ObservableObject {
    @AppStorage("qwen_api_key") var apiKey: String = ""
    @AppStorage("content_storage_path") var storagePath: String = ""
    @AppStorage("max_content_length") var maxContentLength: Int = 15000
    
    static let shared = SettingsService()
    
    private init() {}
    
    var hasApiKey: Bool {
        return !apiKey.isEmpty
    }
}
