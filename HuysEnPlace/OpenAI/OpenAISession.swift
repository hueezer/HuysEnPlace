//
//  OpenAISession.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/4/25.
//

import SwiftUI
import FoundationModels
import Playgrounds

let sharedInstructions = """
    # Identity
    You are a culinary assistant with expert culinary knowledge.

    # Response Formatting
    - Use metric units (grams, liters, centimeters, etc.) for all measurements.
    """

@Observable
class OpenAISession: @unchecked Sendable {
    let endpoint = "https://57a173deb08e.ngrok-free.app/functions/v1/response"
    let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    
    var tools: [AnyEncodableTool] = []
    var instructions: String
    var previousResponseId: String? = nil
    
    init(tools: [AnyEncodableTool] = [], instructions: String) {
        self.tools = tools
        self.instructions = instructions
    }

}

// Methods for generating a standard Response
extension OpenAISession {
    func respond(to prompt: String) async throws -> Response? {
        
        let inputMessage: ResponseInputMessageItem = .init(id: "", content: [
            .input_text(.init(text: prompt))
        ], role: .user, type: .message)
        
        let input: [ResponseItem] = [
            .input_message(inputMessage)
        ]
        
        print("using previousResponseId: \(previousResponseId)")
        if let openaiResponse = try await getResponse(input: input, previousResponseId: previousResponseId) {
            print("setting previousResponseId to: \(openaiResponse.id)")
            self.previousResponseId = openaiResponse.id
            let structuredResponse = try await handleResponse(openaiResponse)
            return structuredResponse
        }
        
        return nil
    }
    
    func handleResponse(_ response: Response) async throws -> Response? {
        print("---------------------------------------")
        print("handleResponse: \(response)")
        print("---------------------------------------")
        for output in response.output {
            switch output {
            case .reasoning(let responseReasoning):
                print("Handling reasoning: \(responseReasoning)")
            case .output_message(let message):
                print("---------------------------------------")
                print("Handling output_message: \(message)")
                print("---------------------------------------")
                let items = try await handleOutputMessage(message)
                print("---------------------------------------")
                print("Returning items: \(items)")
                print("---------------------------------------")
//                return items
                return response
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
            
            if let response = try await getResponse(input: input, previousResponseId: previousResponseId) {
                print("--------------------------------------------------------------------------------")
                print("handleFunctionCallResponse: \(response)")
                print("--------------------------------------------------------------------------------")
                return try await handleResponse(response)
//                return response
            }
        }
        return nil
    }
    
    func getResponse(input: [ResponseItem], previousResponseId: String? = nil) async throws -> Response? {
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

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("Request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("Response: \(response)")
            print("Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw URLError(.badServerResponse)
        }
        
        // Decode the JSON response.
        do {
            let decodedResponse = try JSONDecoder().decode(Response.self, from: data)
            print("decodedResponse: \(decodedResponse)")
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


// Methods for generating a specific type
extension OpenAISession {
    func respond<Content>(to prompt: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) async throws -> Content? where Content: Generable & Decodable {
        
        let inputMessage: ResponseInputMessageItem = .init(id: "", content: [
            .input_text(.init(text: prompt))
        ], role: .user, type: .message)
        
        let input: [ResponseItem] = [
            .input_message(inputMessage)
        ]
        
        print("using previousResponseId: \(previousResponseId)")
        if let openaiResponse = try await getResponse(input: input, generating: type.self, previousResponseId: previousResponseId) {
            print("setting previousResponseId to: \(openaiResponse.id)")
            self.previousResponseId = openaiResponse.id
            let structuredResponse = try await handleResponse(openaiResponse, generating: type)
            return structuredResponse
        }
        
        return nil
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
            
            if let response = try await getResponse(input: input, generating: type, previousResponseId: previousResponseId) {
                return try await handleResponse(response, generating: type)
            }
        }
        return nil
    }
    
    func getResponse<Content>(input: [ResponseItem], generating type: Content.Type = Content.self, previousResponseId: String? = nil) async throws -> Response? where Content: Generable & Decodable {
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
}

// Adapted to accept [AnyEncodableTool] as input for encoding tools
func encodeTools(_ tools: [AnyEncodableTool]) throws -> Data {
    let encoder = JSONEncoder()
    return try encoder.encode(tools)
}

protocol EncodableTool: Tool, Encodable {}

enum AnyEncodableTool: Sendable, Encodable {
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


struct BreadDatabaseTool: Tool, Encodable, Sendable {
    let name = "searchBreadDatabase"
    let description = "Searches a local database for bread recipes."
    let type = "function"
    
    @Generable
    struct Arguments: Sendable {
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

struct ModifyRecipeTool: Tool, Encodable, Sendable {
    let name = "modifyRecipe"
    let description = "Modifies a recipe based on input from the user."
    let type = "function"
    var onCall: @Sendable (GeneratedRecipe) -> Void = { _ in }
    
    @Generable
    struct Arguments: Decodable, Sendable {
        @Guide(description: "How the recipe should be modified.")
        var prompt: String
        var recipe: GeneratedRecipe
    }
    
    func call(arguments: Arguments) async throws -> GeneratedRecipe? {
        print("Called Modify Recipe Tool with args: \(arguments)")
        let fullPrompt = """
            Modify the following recipe acording to these intructions, while only modifying necessary text:
            \(arguments.prompt)
            Recipe:
            \(Recipe(from: arguments.recipe).toJson())
            """
        print("Full Prompt: \(fullPrompt)")

        if let response = try? await OpenAISession(instructions: sharedInstructions).respond(to: fullPrompt, generating: GeneratedRecipe.self) {
            onCall(response)
            return response
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

struct AnyEncodable: Encodable {
    let _encode: (Encoder) throws -> Void

    init<T: Encodable>(erasing encodable: T) {
        _encode = encodable.encode
    }
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

//#Playground {
//
//    let encoded = try encodeTools([
//        .breadDatabase(BreadDatabaseTool()),
//    ])
//    let jsonString = String(data: encoded, encoding: .utf8)
//    
//    let modifyRecipeMessage = "sourdough"
//    
//    let fullPrompt = """
//    Modify the following recipe acording to these intructions:
//    \(modifyRecipeMessage)
//    Recipe:
//    \(banhMiRecipe.toJson())
//    """
//    
////    let fullPrompt = "Make me a sourdough recipe"
//    
//    let session = OpenAISession(
//        // Use the enum case to wrap your tool for type erasure
//        tools: [
////            .breadDatabase(BreadDatabaseTool())
//            .modifyRecipe(ModifyRecipeTool())
//        ],
//        instructions: """
//                # Identity
//
//                You contain all culinary knowledge in the world.
//                When generating recipes, the unit should always be in metric.
//            """
//    )
//    
//    let response = try await session.respond(to: fullPrompt, generating: GeneratedRecipeResponse.self)
//    
//    
//}

#Playground {
    let session = OpenAISession(instructions: "You are a kitchen assistant")
//    let response = try await session.respond(to: "What is ascorbic acid?", generating: Message.self)
    let response = try await session.respond(to: "What is ascorbic acid?", generating: GeneratedMessage.self)
}

