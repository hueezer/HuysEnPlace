//
//  OpenAISession.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/4/25.
//

import SwiftUI
import FoundationModels
import Playgrounds

struct OpenAISession {
    var tools: [AnyEncodableTool] = []
    var instructions: String
    
    func respond<Content>(to prompt: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) async throws -> Content? where Content: Generable & Decodable {
        let endpoint = "https://d313c8f8faa1.ngrok-free.app/functions/v1/response"
        let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
        guard let url = URL(string: endpoint) else {
            print("Invalid URL")
            return nil
        }
        
        let encoder = JSONEncoder()
        guard let schemaData = try? encoder.encode(type.generationSchema) else {
            return nil
        }
        let jsonString = String(data: schemaData, encoding: .utf8)
        
        guard let schema = try? JSONSerialization.jsonObject(with: schemaData, options: []) as? [String: Any] else {
            return nil
        }
        
        guard let encodedTools = try? encoder.encode(tools) else {
            print("Failed to encode tools")
            return nil
        }
        
        print("encodedTools: \(encodedTools)")
        
        let toolsJSON = try JSONSerialization.jsonObject(with: encodedTools) as? [[String: Any]]

        let body: [String: Any] = [
            "instructions": instructions,
            "input": prompt,
            "schema": schema,
            "tools": toolsJSON
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            print("Failed to encode request body.")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                print("Response: \(response)")
                print("Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
                return nil
            }
            
            let decodedIngredient = try JSONDecoder().decode(type.self, from: data)
            print("Decoded ingredient: ", decodedIngredient)
            return decodedIngredient
        } catch {
            print("Generate Ingredient error: \(error)")
            return nil
        }
    }
}

// Adapted to accept [AnyEncodableTool] as input for encoding tools
func encodeTools(_ tools: [AnyEncodableTool]) throws -> Data {
    let encoder = JSONEncoder()
    return try encoder.encode(tools)
}

protocol EncodableTool: Tool, Encodable {}

enum AnyEncodableTool: Encodable {
    case breadDatabase(BreadDatabaseTool)
    // add other tool cases here

    func encode(to encoder: Encoder) throws {
        switch self {
        case .breadDatabase(let tool):
            try tool.encode(to: encoder)
        // handle other tool cases
        }
    }
}


struct BreadDatabaseTool: Tool, Encodable {
    let name = "searchBreadDatabase"
    let description = "Searches a local database for bread recipes."
    let type = "function"
    
    @Generable
    struct Arguments {
        @Guide(description: "The type of bread to search for")
        var searchTerm: String
        @Guide(description: "The number of recipes to get", .range(1...6))
        var limit: Int
    }
    
    func call(arguments: Arguments) async throws -> [String] {
        var recipes: [Recipe] = []
        
        // Put your code here to retrieve a list of recipes from your database.
        
        let formattedRecipes = recipes.map {
            "Recipe for '\($0.title)'"
        }
        return formattedRecipes
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case type
        case parameters
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(type, forKey: .type)
        
        try container.encode(Arguments.generationSchema, forKey: .parameters)
    }
}

#Playground {

    let encoded = try encodeTools([
        .breadDatabase(BreadDatabaseTool()),
    ])
    let jsonString = String(data: encoded, encoding: .utf8)
    
    let session = OpenAISession(
        // Use the enum case to wrap your tool for type erasure
        tools: [
            .breadDatabase(BreadDatabaseTool())
        ],
        instructions: "Help the person with getting weather information"
    )
    
    let response = try await session.respond(to: "Hello", generating: GeneratedRecipeResponse.self)
    
}

