//
//  ResponseInspector.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/14/25.
//

import SwiftUI

struct ResponseInspector: View {
    
    @State private var currentResponse: Response?
    @State private var responses: [Response] = []
    @State private var prompt: String = ""
    
    @State private var modifiedRecipe: Recipe?
    

    
    @State private var session2 = OpenAI(instructions: "")
    
    var body: some View {
        

        
        VStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    Section("Responses") {
                        ForEach(responses) { response in
                            ResponseInspectorView(response: response)
                        }
                    }
                    
                    if let response = currentResponse {
                        Section("Current Response", content: {
                            ResponseInspectorView(response: response)
                        })
                        
                    }
                }
                .padding()
            }
            TextField("What do you want to say?", text: $prompt)
                .padding()
                .submitLabel(.done)
                .onSubmit {
                    Task {
                        await sendMessage(prompt)
                    }
                }
                .multilineTextAlignment(.center)
                .glassEffect()
                .safeAreaPadding()
                
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {

            }
        }
        .onAppear {
            var modifyRecipeTool = ModifyRecipeTool(onCall: { generatedRecipe in
                Task { @MainActor in
                    print("ON CALL RECIPE: \(generatedRecipe.title)")
                    print("generatedRecipe: \(generatedRecipe)")
                    withAnimation {
                        modifiedRecipe = Recipe(from: generatedRecipe)
                    }
                }
            })
            
            session2 = OpenAI(
                tools: [
                    .modifyRecipe(modifyRecipeTool)
                ],
                instructions: """
                    Help the user with any questions related to this recipe. Be very concise.
                    \(banhMiRecipe.toText())
                    """
            )
            
//            currentResponse = Response(id: "resp_689d52cc752081969db6c8956cf424430b38e41cb30a9b37", status: HuysEnPlace.Response.Status.in_progress, output: [], previous_response_id: Optional("resp_689d52b575ac819693136d12b6beedea0b38e41cb30a9b37"), output_text: nil)
        }
        .task {
            await sendMessage("Hi")
        }
    }
    
    func sendMessage(_ prompt: String) async {
        do {
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
            
            let response = Response(id: UUID().uuidString, status: .completed, output: inputItems)
            responses.append(response)
            
            let stream = try await session2.stream(input: inputItems)
            print("Stream: \(stream)")
            try await handleStream(stream)
        } catch {
            print("Streaming failed:", error)
        }
    }
    
    func handleStream(_ stream: AsyncThrowingStream<ResponseStreamEvent, Error>) async throws {
        for try await streamEvent in stream {
//            print("Received event: \(streamEvent)")
//            currentEvent = streamEvent
//            events.append(streamEvent)
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
                currentResponse = nil
            default:
                print("UNHANDLED responseStreamEvent: \(streamEvent)")
            }
        }
    }
}

struct ResponseInspectorView: View {
    var response: Response
    @State private var showJSON = false
    var body: some View {
        VStack(spacing: 16) {
            if let responseInputText = isUserMessage(response) {
                Text(responseInputText.text)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.indigo.opacity(0.2))
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

            } else {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading) {
                        Text("id")
                            .bold()
                        Text(response.id)
                            .fontWeight(.light)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.black.opacity(0.05))
                    
                    VStack(alignment: .leading) {
                        Text("previous_response_id")
                            .bold()
                        Text(response.previous_response_id ?? "nil")
                            .fontWeight(.light)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.black.opacity(0.2))
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                ForEach(response.output) { item in
                    switch item {
                    case .reasoning(let reasoning):
                        VStack(alignment: .leading) {
                            Text("Reasoning: ").bold()
                            VStack {
                                ForEach(reasoning.summary, id: \.self) { summaryText in
                                    Text(summaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.blue.opacity(0.2))
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    case .input_message(let message):
                        VStack(alignment: .leading) {
                            Text("User Message:").bold()
                            ForEach(message.content.indices, id: \.self) { idx in
                                let content = message.content[idx]
                                switch content {
                                case .input_text(let text):
                                    Text(text.text)
                                case .input_image(let image):
                                    Text("Image input: \(image.file_id ?? image.image_url ?? "Unknown")")
                                case .input_file(let file):
                                    Text("File input: \(file.filename ?? file.file_id ?? "Unknown")")
                                }
                            }
                        }
                    case .output_message(let message):
                        VStack(alignment: .leading) {
                            Text("Assistant Message")
                                .bold()
                            VStack {
                                ForEach(message.content.indices, id: \.self) { idx in
                                    let content = message.content[idx]
                                    switch content {
                                    case .output_text(let text):
                                        Text(LocalizedStringKey(text.text))
                                        
                                    case .output_refusal(let refusal):
                                        Text("[Refusal] ").foregroundStyle(.red) + Text(refusal.text)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.blue.opacity(0.2))
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                    case .function_call(let functionCall):
                        VStack(alignment: .leading) {
                            Text("Function Call: \(functionCall.name)").bold()
                            Text("Arguments: \(functionCall.arguments)")
                        }
                    case .function_call_output(let functionCallOutput):
                        VStack(alignment: .leading) {
                            Text("Function Call Output: ").bold()
                            Text(functionCallOutput.output)
                        }
                    case .web_search_call(let webSearchCall):
                        VStack(alignment: .leading) {
                            Text("Web Search Call: ").bold()
                            Text("Status: \(webSearchCall.status.rawValue)")
                        }
                    }
                }
                
                if showJSON {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        Text(JSONString(for: response, format: .prettyPrinted))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.black.opacity(0.8))
                    }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 32))
        .font(.system(.caption2, design: .monospaced))
        .onTapGesture {
            showJSON.toggle()
        }
    }
    
    private func JSONString(for object: any Codable, format: JSONEncoder.OutputFormatting = .sortedKeys) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = format
        do {
            let data = try encoder.encode(object)
            return String(decoding: data, as: UTF8.self)
        } catch {
            return "<encoding error: \(error)>"
        }
    }
    
    func isUserMessage(_ response: Response) -> ResponseInputText? {
        if let firstItem = response.output.first {
            if case .input_message(let inputMessage) = firstItem {
                if inputMessage.role == .user {
                    if let firstContent = inputMessage.content.first {
                        if case .input_text(let responseInputText) = firstContent {
                            return responseInputText
                        }
                    }
                }
            }
        }
        return nil
    }

}

#Preview {
    NavigationStack {
        ResponseInspector()
    }
}
