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
    let endpoint = "https://a6a24bec8777.ngrok-free.app/functions/v1/response"
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

    func stream(input: [ResponseItem]) async throws -> AsyncThrowingStream<ResponseStreamEvent, Error> {
        
        var request = try buildRequest()

        // Input
        let inputArray: [[String: Any]] = input.map { $0.asDictionary() }

        // Tools
        let toolsDict = try buildTools()

        var requestBody: [String: Any] = [
            "instructions": instructions,
            "input": inputArray,
            "tools": toolsDict,
            "stream": "true"
        ]
        
        if let previousResponseId = previousResponseId {
            requestBody["previousResponseId"] = previousResponseId
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
//        let (bytes, response) = try await URLSession.shared.bytes(for: request)
//        
//        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
//            throw URLError(.badServerResponse)
//        }
        
//        return buildResponseStream(bytes: bytes)
        return buildResponseStream(request: request)
    }
    
    func stream<Content>(input: [ResponseItem], generating type: Content.Type = Content.self) async throws -> AsyncThrowingStream<ResponseStreamEvent, Error> where Content: Generable & Decodable {
        
        var request = try buildRequest()
        
        // Schema
        let schema = try buildSchema(generating: type)

        // Input
        let inputArray: [[String: Any]] = input.map { $0.asDictionary() }

        // Tools
        let toolsDict = try buildTools()

        var requestBody: [String: Any] = [
            "instructions": instructions,
            "input": inputArray,
            "schema": schema,
            "tools": toolsDict,
            "stream": "true"
        ]
        
        if let previousResponseId = previousResponseId {
            requestBody["previousResponseId"] = previousResponseId
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
//        let (bytes, response) = try await URLSession.shared.bytes(for: request)
//        
//        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
//            throw URLError(.badServerResponse)
//        }
        
        return buildResponseStream(request: request)
    }
    
    func buildResponseStream(request: URLRequest) -> AsyncThrowingStream<ResponseStreamEvent, Error> {

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                    
                    for try await line in bytes.lines {
                        print("-------------------- LINE BEGIN --------------------")
                        print("LINE: \(line)")
                        print("-------------------- LINE END --------------------")
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { continue }
        
                        if let data = trimmed.data(using: .utf8) {
                            do {
                                let responseStreamEvent = try JSONDecoder().decode(ResponseStreamEvent.self, from: data)
                                if case .responseCreatedEvent(let event) = responseStreamEvent {
                                    print("RESPONSE CREATED: \(event.response)")
                                    self.previousResponseId = event.response.id
                                }
                                continuation.yield(responseStreamEvent)
                            } catch {
                                if let jsonString = String(data: data, encoding: .utf8) {
                                    print("Decoding Error ResponseStreamEvent: \(jsonString)")
                                }
                                continue
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

        }
    }

}

#Playground {
    let stream1 = try await OpenAI(instructions: "You are a kitchen assistant.").stream(input: [])
    Task {
        for try await event in stream1 {
            print(event)
            let e = event
        }
    }
}

