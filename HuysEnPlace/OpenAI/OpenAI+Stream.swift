//
//  OpenAI+Stream.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/20/25.
//

import SwiftUI
import FoundationModels

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
                                if case .responseCompletedEvent(let event) = responseStreamEvent {
                                    var input: [ResponseItem] = []
                                    for item in event.response.output {
                                        switch item {
                                        case .function_call(let functionCall):
                                            print("Should make function_call: \(functionCall)")
                                            
                                            if let functionCallResponse = try await makeFunctionCall(functionCall) {
                                                input.append(functionCallResponse)
                                            }
                                            
                                        default:
                                            print("Default")
                                        }
                                    }
                                    
                                    if !input.isEmpty {
                                        let functionStream = try await stream(input: input)
                                        print("functionStream: \(functionStream)")
                                        for try await functionStreamEvent in functionStream {
                                            print("functionStreamEvent: \(functionStreamEvent)")
                                            continuation.yield(functionStreamEvent)
                                        }
                                    }
                                    
                                }
                                
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
