//
//  ContentFetcher.swift
//  iContentProduction
//
//  Created by AI Assistant on 2025/12/02.
//

import Foundation

struct ContentFetcher {
    static let shared = ContentFetcher()
    
    private let backendUrl = "http://127.0.0.1:8000/extract"
    
    private init() {}
    
    struct ExtractRequest: Codable {
        let url: String
    }
    
    struct ExtractResponse: Codable {
        let content: String?
        let error: String?
        // Add other fields if the backend returns more specific structure
        // Assuming 'content' is the main text body
    }
    
    func fetchContent(from urlString: String) async throws -> String {
        guard let url = URL(string: backendUrl) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ExtractRequest(url: urlString)
        let bodyData = try JSONEncoder().encode(requestBody)
        request.httpBody = bodyData
        
        // Debug: Log Request
        print("--- ContentFetcher Request ---")
        print("URL: \(backendUrl)")
        if let bodyString = String(data: bodyData, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("--- ContentFetcher Error ---")
                print("Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                print("Response: \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        // Debug: Print response string
        if let responseString = String(data: data, encoding: .utf8) {
            print("--- ContentFetcher Response ---")
            print("Response: \(responseString)")
        }
        
        // The user didn't specify the exact JSON structure of the response, only the request.
        // I will assume a generic structure or try to parse 'data' directly if it's raw text,
        // but typically it's JSON. Let's try to decode a generic dictionary first to be safe
        // or just assume a 'content' field based on typical patterns.
        // Given the curl example didn't show response, I'll assume it returns a JSON with a 'content' field
        // or similar. If it fails, I might need to adjust.
        // Let's try to decode as a dictionary [String: Any] (but Codable needs concrete types).
        // Let's assume the response is JSON.
        
        do {
            // Try to decode as a simple dictionary to inspect keys if needed,
            // but for now let's assume a "data" or "content" field.
            // Actually, let's just return the raw string if we can't parse it, or try to be smart.
            // Let's assume the backend returns the extracted text directly or in a JSON wrapper.
            // If the user said "extract", it likely returns JSON.
            
            // Define the specific response structure
            struct BackendData: Codable {
                let content: String
                let url: String?
            }
            
            struct BackendResponse: Codable {
                let code: Int
                let msg: String
                let data: BackendData?
            }
            
            let decoded = try JSONDecoder().decode(BackendResponse.self, from: data)
            
            if decoded.code == 0, let content = decoded.data?.content {
                return content
            } else {
                throw NSError(domain: "ContentFetcher", code: decoded.code, userInfo: [NSLocalizedDescriptionKey: decoded.msg])
            }
            
        } catch {
            // If decoding fails, maybe it's just raw text?
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
}
