//
//  OpenAISession+Stream.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/8/25.
//

import SwiftUI
import FoundationModels
import Playgrounds

extension OpenAISession {

    func stream(input: [ResponseItem], previousResponseId: String? = nil) async throws -> AsyncThrowingStream<ResponseStreamEvent, Error> {
        var request = try baseStreamRequest()

        let encoder = JSONEncoder()

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
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // 3. Iterate over streamed bytes line-by-line
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        print("LINE")
                        print("LINE: \(line)")
                        print("--------------------END OF LINE--------------------")
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { continue }
                        if let data = trimmed.data(using: .utf8) {
                            print("DATA trimmed")
//                            continuation.yield(data)
                            do {
                                let responseStreamEvent = try JSONDecoder().decode(ResponseStreamEvent.self, from: data)
                                print("responseStreamEvent: \(responseStreamEvent)")
                                continuation.yield(responseStreamEvent)
//                                switch decodedResponse {
//
//                                case .responseCreatedEvent(let event):
//                                    print("EVENT: \(event.response)")
//                                    continuation.yield(event.response)
//                                }
                            } catch {
//                                print("Decoding error: \(error)")
                                if let jsonString = String(data: data, encoding: .utf8) {
                                    print("Decoding Error Stream: \(jsonString)")
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
    
    func stream<Content>(input: [ResponseItem], generating type: Content.Type = Content.self, previousResponseId: String? = nil) async throws -> AsyncThrowingStream<ResponseStreamEvent, Error> where Content: Generable & Decodable {
        var request = try baseStreamRequest()
        
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
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // 3. Iterate over streamed bytes line-by-line
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        print("LINE")
                        print("LINE: \(line)")
                        print("--------------------END OF LINE--------------------")
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { continue }
                        if let data = trimmed.data(using: .utf8) {
                            print("DATA trimmed")
//                            continuation.yield(data)
                            do {
                                let responseStreamEvent = try JSONDecoder().decode(ResponseStreamEvent.self, from: data)
                                print("responseStreamEvent: \(responseStreamEvent)")
                                continuation.yield(responseStreamEvent)
//                                switch decodedResponse {
//                                    
//                                case .responseCreatedEvent(let event):
//                                    print("EVENT: \(event.response)")
//                                    continuation.yield(event.response)
//                                }
                            } catch {
//                                print("Decoding error: \(error)")
                                if let jsonString = String(data: data, encoding: .utf8) {
                                    print("Decoding Error Stream: \(jsonString)")
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
    
    func baseStreamRequest() throws -> URLRequest {
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

#Playground {
    let session = OpenAISession(instructions: "You are a kitchen assistant")
//    Task {
//        let userMessage = ResponseInputMessageItem(
//            id: UUID().uuidString,
//            content: [
//                .input_text(ResponseInputText(text: "What is ascorbic acid?"))
//            ],
//            role: .user,
//            status: .in_progress,
//            type: .message
//        )
//        let input: [ResponseItem] = [
//            .input_message(userMessage)
//        ]
//        let stream = try await session.stream(input: input, generating: GeneratedMessage.self)
//        do {
//            for try await line in stream {
//                print(line)
//            }
//        } catch {
//            print("Error: \(error)")
//        }
//    }
    let userMessage = ResponseInputMessageItem(
        id: UUID().uuidString,
        content: [
            .input_text(ResponseInputText(text: "What is ascorbic acid?"))
        ],
        role: .user,
        status: .in_progress,
        type: .message
    )
    let input: [ResponseItem] = [
        .input_message(userMessage)
    ]
//    let request = session.buildRequest(input: input)
}

