//
//  OpenAI.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/23/25.
//

import SwiftUI
import FoundationModels
import Playgrounds

struct OpenAI {
    
    let endpoint = "https://d313c8f8faa1.ngrok-free.app/functions/v1/response"
    let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    
    var prompt: String
    
    func respond<Content>(to input: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) async throws -> Content? where Content: Generable & Decodable {

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

        let body: [String: Any] = [
            "prompt": prompt,
            "input": input,
            "schema": schema
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
    
    static func respondOld(to: String, generating: GenerationSchema) async -> String? {
        let userPrompt = to
        
        // Replace this with your OpenAI API key management
        let apiKey = "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"

        let endpoint = "https://api.openai.com/v1/responses"
        let systemPrompt = """
        You are a food expert who is knows everything about all ingredients in the world.
        """
        
        let model = "gpt-4o-2024-08-06"
        


        do {
            let encoder = JSONEncoder()
            let schemaData = try encoder.encode(generating)
            let jsonString = String(data: schemaData, encoding: .utf8)
            
            let schema = try JSONSerialization.jsonObject(with: schemaData, options: []) as? [String: Any]

            let requestData: [String: Any] = [
                "model": model,
                "input": [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": userPrompt]
                ],
                "text": [
                    "format": [
                        "type": "json_schema",
                        "name": "research_paper_extraction",
                        "schema": schema,
                        "strict": true
                    ]
                ]
            ]

            guard let httpBody = try? JSONSerialization.data(withJSONObject: requestData) else {
                print("Failed to encode OpenAI request body.")
                return nil
            }

            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = httpBody
            print(request)
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
                print("DECODED RESPONSE: ", decodedResponse)
//                let i = GeneratedContent(json: decodedResponse)
                for output in decodedResponse.output {
                    switch output {
                    case .output_message(let message):
                        print("Message received: \(message.content.first)")
//                        messages.append(output)
                        if let firstMessage = message.content.first {
                            print("First message: \(firstMessage)")
                            switch firstMessage {
                            case .output_text(let text):
                                print("TEXT: \(text)")
                                return text.text
//                                if let jsonString = text.text as? String, let ingredientData = jsonString.data(using: .utf8) {
//                                    let decodedIngredient = try JSONDecoder().decode(Ingredient.self, from: ingredientData)
//                                    print("Decoded ingredient: ", decodedIngredient)
//                                } else {
//                                    print("firstMessage is not a valid JSON string.")
//                                }
                            default:
                                print("Unsupported type: \(type(of: firstMessage))")
                            }

                        }
                    case .function_call(let functionCall):
                        print("Function call received: \(functionCall)")
                        print("Received function call name: '\(functionCall.name)'")

                    default:
                        print("Unhandled output: \(output)")
                    }
                }
                
                return nil
            } catch {
                print("Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }
                throw error
            }
        } catch {
            print("OpenAI error: \(error)")
            return nil
        }
    }
    
    static func respondOld<Content>(to prompt: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) async throws -> Content? where Content: Generable & Decodable {
        if let output = await OpenAI.respondOld(to: prompt, generating: type.generationSchema) {
            if let ingredientData = output.data(using: .utf8) {
                let ingredient = try JSONDecoder().decode(type.self, from: ingredientData)
                return ingredient
            }
        }
        return nil
    }
    
    static func respond<Content>(to prompt: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) async throws -> Content? where Content: Generable & Decodable {
        let endpoint = "https://d313c8f8faa1.ngrok-free.app/functions/v1/ingredients"
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

        let body: [String: Any] = [
            "input": prompt,
            "schema": schema
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

#Playground {
    if let output = await OpenAI.respondOld(to: "Bell pepper", generating: Ingredient.generationSchema) {
        if let ingredientData = output.data(using: .utf8) {
            let ingredient = try JSONDecoder().decode(Ingredient.self, from: ingredientData)
        }
    }
    
    let i = try await OpenAI.respond(to: "Daikon", generating: Ingredient.self, includeSchemaInPrompt: true)
}
