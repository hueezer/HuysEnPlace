//
//  StreamTestView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/9/25.
//

import SwiftUI

private func JSONString(for event: any Codable, format: JSONEncoder.OutputFormatting = .sortedKeys) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = format
    do {
        let data = try encoder.encode(event)
        return String(decoding: data, as: UTF8.self)
    } catch {
        return "<encoding error: \(error)>"
    }
}

struct StreamTestView: View {
    
    @State private var session = OpenAISession(instructions: """
                    ## Identity

                    You contain all culinary knowledge in the world. Produce content that is both interesting, concise and factual. It should be the most interesting culinary book ever to exist.
                    
                    ## Format
                    Each section should have a title and should be bold.
                    Sections should be no longer than 5 sentences.
                    Italicize any important information that should be emphasized.
                    Use lists with bullet points when needed.
                    Respond in markdown.
                    
                    ## Here is the markdown supported:
                    This is regular text.
                    * This is **bold** text, this is *italic* text, and this is ***bold, italic*** text.
                    ~~A strikethrough example~~
                    `Monospaced works too`
                    
                    Only use these supported markdown styles
                    """)
    
    @State private var session2 = OpenAI(instructions: """
                    ## Identity

                    You contain all culinary knowledge in the world. Produce content that is both interesting, concise and factual. It should be the most interesting culinary book ever to exist.
                    
                    ## Format
                    Each section should have a title and should be bold.
                    Sections should be no longer than 5 sentences.
                    Italicize any important information that should be emphasized.
                    Use lists with bullet points when needed.
                    Respond in markdown.
                    
                    ## Here is the markdown supported:
                    This is regular text.
                    * This is **bold** text, this is *italic* text, and this is ***bold, italic*** text.
                    ~~A strikethrough example~~
                    `Monospaced works too`
                    
                    Only use these supported markdown styles
                    """)
    
    @State private var outputText: String = ""
    @State private var status: String = ""
    
    @State private var currentResponse: Response?
    @State private var currentEvent: ResponseStreamEvent?
    @State private var responses: [Response] = []
    @State private var events: [ResponseStreamEvent] = []
    
    var body: some View {
        List {
            if let response = currentResponse {
                VStack {
                    Text("ID: ")
                    Text(response.id)
                        .bold()
                    Text("PREVIOUS RESPONSE ID: ")
                    Text(response.previous_response_id ?? "nil")
                        .bold()
                    Text(JSONString(for: response, format: .prettyPrinted))
//                    ForEach(response.output) { item in
//                        switch item {
//                        case .reasoning(let reasoning):
//                            VStack(alignment: .leading) {
//                                Text("Reasoning: ").bold()
//                                ForEach(reasoning.summary, id: \.self) { summaryText in
//                                    Text(summaryText)
//                                }
//                            }
//                        case .input_message(let message):
//                            VStack(alignment: .leading) {
//                                Text("User Message:").bold()
//                                ForEach(message.content.indices, id: \.self) { idx in
//                                    let content = message.content[idx]
//                                    switch content {
//                                    case .input_text(let text):
//                                        Text(text.text)
//                                    case .input_image(let image):
//                                        Text("Image input: \(image.file_id ?? image.image_url ?? "Unknown")")
//                                    case .input_file(let file):
//                                        Text("File input: \(file.filename ?? file.file_id ?? "Unknown")")
//                                    }
//                                }
//                            }
//                        case .output_message(let message):
//                            VStack(alignment: .leading) {
//                                Text("Assistant Message:").bold()
//                                ForEach(message.content.indices, id: \.self) { idx in
//                                    let content = message.content[idx]
//                                    switch content {
//                                    case .output_text(let text):
//                                        Text(text.text)
//                                    case .output_refusal(let refusal):
//                                        Text("[Refusal] ").foregroundStyle(.red) + Text(refusal.text)
//                                    }
//                                }
//                            }
//                        case .function_call(let functionCall):
//                            VStack(alignment: .leading) {
//                                Text("Function Call: \(functionCall.name)").bold()
//                                Text("Arguments: \(functionCall.arguments)")
//                            }
//                        case .function_call_output(let functionCallOutput):
//                            VStack(alignment: .leading) {
//                                Text("Function Call Output: ").bold()
//                                Text(functionCallOutput.output)
//                            }
//                        case .web_search_call(let webSearchCall):
//                            VStack(alignment: .leading) {
//                                Text("Web Search Call: ").bold()
//                                Text("Status: \(webSearchCall.status.rawValue)")
//                            }
//                        }
//                    }
                        
                    if let event = currentEvent {
                        Text(event.status() ?? "")
                    }
                }
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
            }

            ForEach(responses, id: \.self) { response in
                VStack(alignment: .leading) {
                    Text("ID:")
                    Text(response.id)
                        .bold()
                    Text("Previous Response ID:")
                    Text(response.previous_response_id ?? "nil")
                        .bold()
                    Text(response.output_text ?? "no output_text")
                    Text(JSONString(for: response, format: .prettyPrinted))
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                }
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
            }
//            ForEach(events, id: \.self) { event in
//                HStack {
//                    Text(JSONString(for: event, format: .prettyPrinted))
//                        .font(.system(.caption2, design: .monospaced))
//                        .textSelection(.enabled)
//                        .padding(.vertical, 4)
//                }
//            }
        }
        .overlay(alignment: .bottom) {
            HStack {
                Button("Action 1") {
                    if let currentResponse = currentResponse {
                        self.currentResponse = nil
                        sendMessage("What are we doing?")
                    }

                }
                .buttonStyle(.glassProminent)
                
                Button("Action 2") {
                    if let currentResponse = currentResponse {
                        self.currentResponse = nil
                        sendMessage("What was the first thing I said?")
                    }

                }
                .buttonStyle(.glassProminent)
            }
            .padding()
        }
//        .task {
//            do {
//                let _ = try await session.stream(input: "Can you tell me about bread flour? Just the first 200 words is great.") { text in
//                    outputText  = text
//                } onDelta: { delta in
//                    outputText += delta
//                } onCompleted: { text in
//                    outputText  = text
//                }
////                let streamEvents = try await session.stream(input: input)
//                status = "Started..."
//            } catch {
//                print("Streaming failed:", error)
//            }
//
//        }
        .task {
            do {
                let userMessage = ResponseInputMessageItem(
                    id: UUID().uuidString,
                    content: [
                        .input_text(ResponseInputText(text: "Hi"))
                    ],
                    role: .user,
                    type: .message
                )
                let inputItems: [ResponseItem] = [
                    .input_message(userMessage)
                ]
                
                let stream = try await session2.stream(input: inputItems)
                print("Stream: \(stream)")
                try await handleStream(stream)
            } catch {
                print("Streaming failed:", error)
            }
        }
    }
    
    func sendMessage(_ prompt: String) {
        Task {
            let userMessage = ResponseInputMessageItem(
                id: UUID().uuidString,
                content: [
                    .input_text(ResponseInputText(text: prompt))
                ],
                role: .user,
                type: .message
            )
            let inputItems: [ResponseItem] = [
                .input_message(userMessage)
            ]
            
            let stream = try await session2.stream(input: inputItems)
            print("Stream: \(stream)")
            try await handleStream(stream)
        }
    }
    
    func handleStream(_ stream: AsyncThrowingStream<ResponseStreamEvent, Error>) async throws {
        for try await streamEvent in stream {
            print("Received event: \(streamEvent)")
            currentEvent = streamEvent
            events.append(streamEvent)
            switch streamEvent {
                
            case .responseCreatedEvent(let event):
                currentResponse = event.response
            case .responseOutputItemAddedEvent(let event):
                currentResponse?.output.append(event.item)
            case .responseContentPartAddedEvent(let event):
                if var responseItem = currentResponse?.output[event.output_index] {
                    if case .output_message(var message) = responseItem {
                        message.content.append(event.part)
                        currentResponse?.output[event.output_index] = .output_message(message)
                    }
                }
            case .responseOutputTextDeltaEvent(let event):
                guard var response = currentResponse, response.output.indices.contains(event.output_index) else { break }
                
                var responseItem = response.output[event.output_index]
                if case .output_message(var message) = responseItem {
                    print("debug message.content: \(message.content)")
                    print("debug message.content.indices: \(message.content.indices)")
                    print("debug event.content_index: \(event.content_index)")
                    if message.content.indices.contains(event.content_index) {
                        var content = message.content[event.content_index]
                        if case .output_text(var outputText) = content {
                            outputText.text += event.delta
                            content = .output_text(outputText)
                            message.content[event.content_index] = content
                            responseItem = .output_message(message)
                            response.output[event.output_index] = responseItem
                            currentResponse = response
                        }
                    }
                }
            case .responseCompletedEvent(let event):
                responses.append(event.response)
            default:
                print("UNHANDLED responseStreamEvent: \(streamEvent)")
            }
        }
    }
}

#Preview {
    StreamTestView()
}

