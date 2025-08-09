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
    func streamResponse<Content>(to prompt: String, generating type: Content.Type = Content.self, includeSchemaInPrompt: Bool = true, options: GenerationOptions = GenerationOptions()) -> AsyncThrowingStream<Content, Error> where Content: Generable & Decodable {
        AsyncThrowingStream { continuation in
            // TODO: Implement streaming logic here
            // Example placeholder:
            // continuation.yield(parsedContent)

            // End the stream when complete:
            continuation.finish()
        }
    }
    
    func streamResponse<Content>(input: [ResponseItem], generating type: Content.Type = Content.self, previousResponseId: String? = nil) async throws -> AsyncThrowingStream<Response, Error> where Content: Generable & Decodable {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        let encoder = JSONEncoder()
        guard let schemaData = try? encoder.encode(type.generationSchema) else {
            throw URLError(.cannotParseResponse)
        }
        let jsonString = String(data: schemaData, encoding: .utf8)

        guard let schema = try? JSONSerialization.jsonObject(with: schemaData, options: []) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let inputArray: [[String: Any]] = input.map { $0.asDictionary() }

        guard let encodedTools = try? encoder.encode(tools) else {
            throw URLError(.cannotParseResponse)
        }
        let toolsJSON = try JSONSerialization.jsonObject(with: encodedTools) as? [[String: Any]]

        var requestBody: [String: Any] = [
            "instructions": instructions,
            "input": inputArray,
            "schema": schema,
            "tools": toolsJSON,
            "stream": "true"
        ]
        if let previousResponseId = previousResponseId {
            requestBody["previousResponseId"] = previousResponseId
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        
        // If your server is SSE, uncomment the next line:
        // request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        // If NDJSON, you can use:
        // request.addValue("application/x-ndjson", forHTTPHeaderField: "Accept")

        
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        print("BYTES: \(bytes)")
        print("BYTES LINES: \(bytes.lines)")

        for try await line in bytes.lines {
            print("LINE: \(line)")
            let data = try JSONDecoder().decode(Response.self, from: Data(line.utf8))
            print("RESPONSE DATA: \(data)")
        }

        return AsyncThrowingStream<Response, Error> { continuation in
            
//            let (bytes, response) = try await URLSession.shared.bytes(for: request)
//            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                throw URLError(.badServerResponse)
//            }
//            for try await line in bytes.lines {
//                let data = try JSONDecoder().decode(Response.self, from: Data(line.utf8))
//                print("RESPONSE DATA: \(data)")
//            }
            
//            let (bytes, response) = try await URLSession.shared.bytes(for: request)
//            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                throw URLError(.badServerResponse)
//            }
//    
//            print("BYTES: \(bytes)")
//            print("BYTES LINES: \(bytes.lines)")
//    
//            for try await line in bytes.lines {
//                print("LINE: \(line)")
//                let data = try JSONDecoder().decode(Response.self, from: Data(line.utf8))
//                print("RESPONSE DATA: \(data)")
//            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    continuation.finish(throwing: URLError(.badServerResponse))
                    return
                }
                guard let data = data else {
                    continuation.finish(throwing: URLError(.badServerResponse))
                    return
                }
                // Assume response is NDJSON (newline-delimited objects)
                let decoder = JSONDecoder()
                let lines = String(decoding: data, as: UTF8.self).split(separator: "\n")
                print("LINE COUNT: \(lines.count)")
                for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    do {
                        print("LINE:")
                        let object = try decoder.decode(Response.self, from: Data(line.utf8))
                        continuation.yield(object)
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }
                }
                continuation.finish()
            }
            task.resume()
        }
    }
    
    func readStreamingResponse(input: [ResponseItem], previousResponseId: String? = nil) async throws -> AsyncThrowingStream<ResponseStreamEvent, Error> {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        let encoder = JSONEncoder()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let inputArray: [[String: Any]] = input.map { $0.asDictionary() }

        guard let encodedTools = try? encoder.encode(tools) else {
            throw URLError(.cannotParseResponse)
        }
        let toolsJSON = try JSONSerialization.jsonObject(with: encodedTools) as? [[String: Any]]

        var requestBody: [String: Any] = [
            "instructions": instructions,
            "input": inputArray,
            "tools": toolsJSON,
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
    
    func readStreamingResponse<Content>(input: [ResponseItem], generating type: Content.Type = Content.self, previousResponseId: String? = nil) async throws -> AsyncThrowingStream<ResponseStreamEvent, Error> where Content: Generable & Decodable {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        let encoder = JSONEncoder()
        guard let schemaData = try? encoder.encode(type.generationSchema) else {
            throw URLError(.cannotParseResponse)
        }
        let jsonString = String(data: schemaData, encoding: .utf8)

        guard let schema = try? JSONSerialization.jsonObject(with: schemaData, options: []) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let inputArray: [[String: Any]] = input.map { $0.asDictionary() }

        guard let encodedTools = try? encoder.encode(tools) else {
            throw URLError(.cannotParseResponse)
        }
        let toolsJSON = try JSONSerialization.jsonObject(with: encodedTools) as? [[String: Any]]

        var requestBody: [String: Any] = [
            "instructions": instructions,
            "input": inputArray,
            "schema": schema,
            "tools": toolsJSON,
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
    
}

#Playground {
    let session = OpenAISession(instructions: "You are a kitchen assistant")
    Task {
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
        let stream = try await session.streamResponse(input: input, generating: GeneratedMessage.self)
        do {
            for try await line in stream {
                print(line)
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

