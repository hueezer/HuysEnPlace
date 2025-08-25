//
//  OpenAI.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/12/25.
//

import SwiftUI
import FoundationModels
import Playgrounds

@MainActor
final class OpenAI {
    let endpoint = "https://4910bc73291d.ngrok-free.app/functions/v1/response"
    let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    
    var tools: [AnyEncodableTool]
    var instructions: String
    var previousResponseId: String? = nil
    
    init(tools: [AnyEncodableTool] = [], instructions: String) {
        self.tools = []
        self.instructions = instructions
        self.tools = tools
    }
    
    func buildRequest() throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        return request
    }
    
    func buildTools() throws -> [[String: Any]] {
        let encoder = JSONEncoder()
        guard let encodedTools = try? encoder.encode(tools) else {
            throw URLError(.cannotParseResponse)
        }
        let toolsDict = try JSONSerialization.jsonObject(with: encodedTools) as? [[String: Any]]
        return toolsDict ?? []
    }
    
    func buildSchema<Content>(generating type: Content.Type = Content.self) throws -> [String: Any] where Content: Generable & Decodable {
        let encoder = JSONEncoder()
        guard let schemaData = try? encoder.encode(type.generationSchema) else {
            throw URLError(.cannotParseResponse)
        }
        let jsonString = String(data: schemaData, encoding: .utf8)

        guard let schema = try? JSONSerialization.jsonObject(with: schemaData, options: []) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return schema
    }
}

extension OpenAI {
    func respond(to prompt: String) async throws -> Response? {
        
        let inputMessage: ResponseInputMessageItem = .init(id: "", content: [
            .input_text(.init(text: prompt))
        ], role: .user, type: .message)
        
        let input: [ResponseItem] = [
            .input_message(inputMessage)
        ]
        
        print("using previousResponseId: \(previousResponseId)")
        if let openaiResponse = try await makeRequest(input: input, previousResponseId: previousResponseId) {
            print("setting previousResponseId to: \(openaiResponse.id)")
            self.previousResponseId = openaiResponse.id
            let structuredResponse = try await handleResponse(openaiResponse)
            return structuredResponse
        } else {
            print("previousREsponseId was nil NO RESPONSE from openai")
        }
        
        return nil
    }
    
    func makeRequest(input: [ResponseItem], previousResponseId: String? = nil) async throws -> Response? {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        let encoder = JSONEncoder()
        
        // Create and configure the request.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.timeoutInterval = 300
        
        let inputArray: [[String: Any]] = input.map { message in
            message.asDictionary()
        }
        
        print("Input array: \(inputArray)")
        
        guard let encodedTools = try? encoder.encode(tools) else {
            print("Failed to encode tools")
            return nil
        }
        
        print("encodedTools: \(encodedTools)")
        
        let toolsJSON = try JSONSerialization.jsonObject(with: encodedTools) as? [[String: Any]]
        
        var requestBody: [String: Any] = [
            "instructions": instructions,
            "input": inputArray,
            "tools": toolsJSON
        ]
        
        if let previousResponseId = previousResponseId {
            requestBody["previousResponseId"] = previousResponseId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
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
    
    func handleResponse(_ response: Response) async throws -> Response? {
        print("handleResponse: \(response)")
        for output in response.output {
            switch output {
            case .reasoning(let responseReasoning):
                print("Handling reasoning: \(responseReasoning)")
            case .output_message(let message):
                print("Handling output_message: \(message)")
                let items = try await handleOutputMessage(message)
                return items
            case .function_call(let functionCall):
                print("Handling function_call: \(functionCall)")
                let items = try await handleFunctionCall(functionCall, previousResponseId: response.id)
                return items
            case .web_search_call(let responseWebSearchCall):
                print("Unhandled web_search_call: \(responseWebSearchCall)")
            default:
                print("Unhandled output: \(output)")
            }
        }
        return nil
    }
    
    func handleFunctionCall(_ functionCall: ResponseFunctionToolCall, previousResponseId: String? = nil) async throws -> Response? {
        if let tool = tools.first(where: { $0.name == functionCall.name }) {
            let toolResponse = try await tool.call(arguments: functionCall.arguments)
            
            let toolResponseString: String
            if let encodableResponse = toolResponse as? Encodable,
               let data = try? JSONEncoder().encode(AnyEncodable(erasing: encodableResponse)),
               let jsonString = String(data: data, encoding: .utf8) {
                toolResponseString = jsonString
            } else {
                toolResponseString = String(describing: toolResponse)
            }
            let toolCallOutput: ResponseFunctionToolCallOutput = .init(call_id: functionCall.call_id, output: toolResponseString)
            
            let input: [ResponseItem] = [
                .function_call_output(toolCallOutput)
            ]
            
            if let response = try await makeRequest(input: input, previousResponseId: previousResponseId) {
                return try await handleResponse(response)
            }
        }
        return nil
    }
    
    func handleOutputMessage(_ message: ResponseOutputMessage) async throws -> Response? {
        for content in message.content {
            switch content {
            case .output_text(let responseOutputText):
                if let data = responseOutputText.text.data(using: .utf8) {
                    let decoded = try? JSONDecoder().decode(Response.self, from: data)
                    return decoded
                }
            case .output_refusal(let responseOutputRefusal):
                print("Unhandle output_refusal: \(responseOutputRefusal)")
            }
        }
        return nil
    }
}

extension OpenAI {
    
    func respond<Content>(to prompt: String, generating type: Content.Type = Content.self) async throws -> Content? where Content: Generable & Decodable {
        
        let inputMessage: ResponseInputMessageItem = .init(id: "", content: [
            .input_text(.init(text: prompt))
        ], role: .user, type: .message)
        
        let input: [ResponseItem] = [
            .input_message(inputMessage)
        ]
        
        print("using previousResponseId: \(previousResponseId)")
        if let openaiResponse = try await makeRequest(input: input, generating: type.self, previousResponseId: previousResponseId) {
            print("setting previousResponseId to: \(openaiResponse.id)")
            self.previousResponseId = openaiResponse.id
            let structuredResponse = try await handleResponse(openaiResponse, generating: type)
            return structuredResponse
        } else {
            print("previousREsponseId was nil NO RESPONSE from openai")
        }
        
        return nil
    }
    
}


extension OpenAI {

    func makeRequest<Content>(input: [ResponseItem], generating type: Content.Type = Content.self, previousResponseId: String? = nil) async throws -> Response? where Content: Generable & Decodable {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        let encoder = JSONEncoder()
        guard let schemaData = try? encoder.encode(type.generationSchema) else {
            return nil
        }
        let jsonString = String(data: schemaData, encoding: .utf8)
        
        guard let schema = try? JSONSerialization.jsonObject(with: schemaData, options: []) as? [String: Any] else {
            return nil
        }
        
        // Create and configure the request.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.timeoutInterval = 300
        
        let inputArray: [[String: Any]] = input.map { message in
            message.asDictionary()
        }
        
        print("Input array: \(inputArray)")
        
        guard let encodedTools = try? encoder.encode(tools) else {
            print("Failed to encode tools")
            return nil
        }
        
        print("encodedTools: \(encodedTools)")
        
        let toolsJSON = try JSONSerialization.jsonObject(with: encodedTools) as? [[String: Any]]
        
        var requestBody: [String: Any] = [
            "instructions": instructions,
            "input": inputArray,
            "schema": schema,
            "tools": toolsJSON
        ]
        
        if let previousResponseId = previousResponseId {
            requestBody["previousResponseId"] = previousResponseId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
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
    
    func handleResponse<Content>(_ response: Response, generating type: Content.Type = Content.self) async throws -> Content? where Content: Generable & Decodable {
        print("handleResponse: \(response)")
        for output in response.output {
            switch output {
            case .reasoning(let responseReasoning):
                print("Handling reasoning: \(responseReasoning)")
            case .output_message(let message):
                print("Handling output_message: \(message)")
                let items = try await handleOutputMessage(message, generating: type)
                return items
            case .function_call(let functionCall):
                print("Handling function_call: \(functionCall)")
                let items = try await handleFunctionCall(functionCall, generating: type, previousResponseId: response.id)
                return items
            case .web_search_call(let responseWebSearchCall):
                print("Unhandled web_search_call: \(responseWebSearchCall)")
            default:
                print("Unhandled output: \(output)")
            }
        }
        return nil
    }
    
    func handleOutputMessage<Content>(_ message: ResponseOutputMessage, generating type: Content.Type = Content.self) async throws -> Content? where Content: Generable & Decodable {
        for content in message.content {
            switch content {
            case .output_text(let responseOutputText):
                if let data = responseOutputText.text.data(using: .utf8) {
                    let decoded = try? JSONDecoder().decode(type.self, from: data)
                    return decoded
                }
            case .output_refusal(let responseOutputRefusal):
                print("Unhandle output_refusal: \(responseOutputRefusal)")
            }
        }
        return nil
    }
}

extension OpenAI {

    func makeFunctionCall(_ functionCall: ResponseFunctionToolCall) async throws -> ResponseItem? {
        if var tool = tools.first(where: { $0.name == functionCall.name }) {
            
            let toolResponse = try await tool.callWithOpenAI(arguments: functionCall.arguments)
            let toolResponseString: String
            if let encodableResponse = toolResponse as? Encodable,
               let data = try? JSONEncoder().encode(AnyEncodable(erasing: encodableResponse)),
               let jsonString = String(data: data, encoding: .utf8) {
                toolResponseString = jsonString
            } else {
                toolResponseString = String(describing: toolResponse)
            }
            let toolCallOutput: ResponseFunctionToolCallOutput = .init(call_id: functionCall.call_id, output: toolResponseString)
            
            return ResponseItem.function_call_output(toolCallOutput)
            
        }
        return nil
    }
    
    func handleFunctionCall<Content>(_ functionCall: ResponseFunctionToolCall, generating type: Content.Type = Content.self, previousResponseId: String? = nil) async throws -> Content? where Content: Generable & Decodable {
        if let tool = tools.first(where: { $0.name == functionCall.name }) {
            let toolResponse = try await tool.call(arguments: functionCall.arguments)
            
            let toolResponseString: String
            if let encodableResponse = toolResponse as? Encodable,
               let data = try? JSONEncoder().encode(AnyEncodable(erasing: encodableResponse)),
               let jsonString = String(data: data, encoding: .utf8) {
                toolResponseString = jsonString
            } else {
                toolResponseString = String(describing: toolResponse)
            }
            let toolCallOutput: ResponseFunctionToolCallOutput = .init(call_id: functionCall.call_id, output: toolResponseString)
            
            let input: [ResponseItem] = [
                .function_call_output(toolCallOutput)
            ]
            
            if let response = try await makeRequest(input: input, generating: type, previousResponseId: previousResponseId) {
                return try await handleResponse(response, generating: type)
            }
        }
        return nil
    }

}

#Playground {
    let response = try await OpenAI(instructions: "You are a kitchen assistant. ").respond(to: "Sourdough Bread ", generating: GeneratedRecipe.self)
}

