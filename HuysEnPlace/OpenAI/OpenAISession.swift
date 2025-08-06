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
//            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
//                print("Request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
//                print("Response: \(response)")
//                print("Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
//                return nil
//            }
//            
//            print("DATA (raw): \(data)")
//            print("DATA (utf8): \(String(data: data, encoding: .utf8) ?? "<non-utf8 data>")")
//            
//            let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
//            print("Decoded response: ", decodedResponse)
            
            let openaiResponse = try await makeRequest(request: request)
            
            for output in openaiResponse.output {
                switch output {
                case .output_message(let message):
                    print("Message received: \(message)")
                case .function_call(let functionCall):
                    print("Function call received: \(functionCall)")
                    print("Received function call name: '\(functionCall.name)'")
                    
                    if let tool = tools.first(where: { $0.name == functionCall.name }) {
                        print("FOUND TOOL: \(tool)")
                        print("args: \(functionCall.arguments)")
                        try await tool.call(arguments: functionCall.arguments)
                    } else {
                        print("TOOL NOT FOUND")
                    }
                    
//                    if let tool = tools.first(where: { tool in
//                        switch tool {
//                        case .breadDatabase(let breadTool):
//                            return breadTool.name == functionCall.name
//                        case .modifyRecipe(let modifyTool):
//                            return modifyTool.name == functionCall.name
//                        }
//                    }) {
//                        print("FOUND TOOL: \(tool)")
//                    } else {
//                        print("TOOL NOT FOUND")
//                    }
                    
                    
//                    if functionCall.name == "modifyRecipe" {
//                        if case let .modifyRecipe(modifyRecipeTool) = tool {
//                            // Now you have the modifyRecipeTool instance
//                        }
//                    } else {
//                        print("NO MATCHING FUNCTION NAME")
//                    }
                default:
                    print("Unhandled output: \(output)")
                }
            }
            
            return nil
            
//            let decodedIngredient = try JSONDecoder().decode(type.self, from: decodedResponse)
//            print("Decoded ingredient: ", decodedIngredient)
//            return decodedIngredient
            
//            let decodedIngredient = try JSONDecoder().decode(type.self, from: data)
//            print("Decoded ingredient: ", decodedIngredient)
//            return decodedIngredient
        } catch {
            print("Decode error: \(error)")
            return nil
        }
    }
    
    func makeRequest(request: URLRequest) async throws -> Response {
        // Perform the network request.
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print(response)
        print("END OF RESPONSE -----------------------")
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("Request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Response: \(response)")
            print("Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw URLError(.badServerResponse)
        }
        
        // Decode the JSON response.
        do {
            let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
            print(decodedResponse)
            return decodedResponse
        } catch {
            print("Decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            throw error
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
    case modifyRecipe(ModifyRecipeTool)
    // add other tool cases here

    func encode(to encoder: Encoder) throws {
        switch self {
        case .breadDatabase(let tool):
            try tool.encode(to: encoder)
        case .modifyRecipe(let tool):
            try tool.encode(to: encoder)
        // handle other tool cases
        }
    }
    
    var name: String {
        switch self {
        case .breadDatabase(let tool):
            return tool.name
        case .modifyRecipe(let tool):
            return tool.name
        }
    }
    
    // Type-erased call method with runtime type checking of arguments
    func call(arguments: String) async throws -> Any {
        guard let data = arguments.data(using: .utf8) else {
            throw NSError(domain: "AnyEncodableTool", code: 2, userInfo: [NSLocalizedDescriptionKey: "Arguments string is not valid UTF-8"])
        }
        
        switch self {
        case .breadDatabase(let tool):
            guard let typedArgs = arguments as? BreadDatabaseTool.Arguments else {
                throw NSError(domain: "AnyEncodableTool", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid arguments type for BreadDatabaseTool"])
            }
            return try await tool.call(arguments: typedArgs)
        case .modifyRecipe(let tool):

            let typedArgs = try JSONDecoder().decode(ModifyRecipeTool.Arguments.self, from: data)
            return try await tool.call(arguments: typedArgs)
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

struct ModifyRecipeTool: Tool, Encodable {
    let name = "modifyRecipe"
    let description = "Modifies a recipe based on input from the user."
    let type = "function"
    var onCall: @Sendable (GeneratedRecipe) -> Void = { _ in }
    
    @Generable
    struct Arguments: Decodable {
        @Guide(description: "How the recipe should be modified.")
        var prompt: String
        var recipe: GeneratedRecipe
    }
    
    func call(arguments: Arguments) async throws -> GeneratedRecipe? {
        print("Called Modify Recipe Tool with args: \(arguments)")
        let fullPrompt = """
            Modify the following recipe acording to these intructions:
            \(arguments.prompt)
            Recipe:
            \(arguments.recipe)
            """
        print("Full Prompt: \(fullPrompt)")

        if let generatedRecipeResponse = try await OpenAI.respond(to: fullPrompt, generating: GeneratedRecipe.self) {
            
            print("GeneratedRecipeResponse: \(generatedRecipeResponse)")
            onCall(generatedRecipeResponse)
            return generatedRecipeResponse
        }
        return nil
//        return generatedRecipeResponse
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
    
    let modifyRecipeMessage = "sourdough"
    
    let fullPrompt = """
    Modify the following recipe acording to these intructions:
    \(modifyRecipeMessage)
    Recipe:
    \(banhMiRecipe.toJson())
    """
    
//    let fullPrompt = "Make me a sourdough recipe"
    
    let session = OpenAISession(
        // Use the enum case to wrap your tool for type erasure
        tools: [
//            .breadDatabase(BreadDatabaseTool())
            .modifyRecipe(ModifyRecipeTool())
        ],
        instructions: """
                # Identity

                You contain all culinary knowledge in the world.
                When generating recipes, the unit should always be in metric.
            """
    )
    
    let response = try await session.respond(to: fullPrompt, generating: GeneratedRecipeResponse.self)
    
    
}

