//
//  ChatResponseView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/15/25.
//

import SwiftUI

struct ChatResponseView: View {
    @Binding var response: Response
    var showJSON = false
    var isUser: Bool {
        isUserMessage(response) != nil
    }
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 50)
            }

            VStack(spacing: 16) {
//                if showJSON {
//                    VStack(alignment: .leading, spacing: 0) {
//                        
//                        Text(JSONString(for: response, format: .prettyPrinted))
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .padding()
//                            .background(.black.opacity(0.8))
//                    }
//                    .clipped()
//                    .clipShape(RoundedRectangle(cornerRadius: 16))
//                    .foregroundStyle(.white)
//                    .font(.caption)
//                }
                Text("\(response)")
                

                if let responseInputText = isUserMessage(response) {
                    Text(responseInputText.text)
                    
                } else {
                    if response.output.isEmpty {
                        ProgressView()
                    }
                    
                    ForEach(response.output) { item in
                        switch item {
                        case .reasoning(let reasoning):
                            if !reasoning.summary.isEmpty {
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
                            }

                        case .output_message(let message):
                            if message.content.isEmpty {
                                ProgressView()
                            }
                            
                            ForEach(message.content.indices, id: \.self) { idx in
                                let content = message.content[idx]
                                switch content {
                                case .output_text(let text):
                                    Text(LocalizedStringKey(text.text))
                                case .output_refusal(let refusal):
                                    Text("[Refusal] ").foregroundStyle(.red) + Text(refusal.text)
                                }
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding(16)
            .padding(.horizontal, 8)
            .glassEffect(isUser ? .regular.tint(.blue).interactive() : .regular.interactive(), in: RoundedRectangle(cornerRadius: 32))
            //        .glassEffectID(message.id, in: namespace)
            .foregroundStyle(isUser ? .white : .primary)
//            .font(.system(.subheadline, design: .monospaced))
            .font(.system(.callout, design: .rounded))
//            .onTapGesture {
//                showJSON.toggle()
//            }
            
            if !isUser {
                Spacer(minLength: 0)
            }
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
    @Previewable @State var response: Response = Response(id: "1", status: .completed, output: [
        .input_message(.init(id: "1", content: [.input_text(.init(text: "Hello, this is just a test."))], role: .user, type: .message))
    ])
    
    @Previewable @State var response2: Response = Response(id: "2", status: .completed, output: [
        .output_message(.init(id: "2", content: [.output_text(.init(type: .output_text, text: "Hello. Make this some longer pience of text to make sure it's rendering correctly."))], role: .assistant, status: .completed, type: .message))
    ])
    
    @Previewable @State var response3: Response = Response(id: "3", status: .completed, output: [
        .output_message(.init(id: "3", content: [], role: .assistant, status: .completed, type: .message))
    ])
    
    @Previewable @State var status: String = "NONE"
    VStack {
        ChatResponseView(response: $response)
        ChatResponseView(response: $response2)
        Text(status)
        ChatResponseView(response: $response3)
        Button("Update") {
//            response3.output[0] = .output_message(.init(id: "3", content: [.output_text(.init(type: .output_text, text: "Hello"))], role: .assistant, status: .completed, type: .message))
//            response3.output[0].content[0].text += "Hello"
            if case .output_message(var message) = response3.output[0] {
                status = "CASE 0"
                if message.content.indices.contains(0),
                   case .output_text(var textItem) = message.content[0] {
                    status = "CASE 1"
                    var newResponse = response3
                    newResponse.id = textItem.text
                    var newText = textItem.text
                    newText += "Hello"
                    message.content[0] = .output_text(.init(type: .output_text, text: newText))
                    
                    newResponse.output[0] = .output_message(message)
                    response3 = newResponse
                    status = "\(response3)"
                } else {
                    status = "CASE 2"
                    message.content.append(.output_text(.init(type: .output_text, text: "")))
                    response3.output[0] = .output_message(message)
                }
            } else {
                status = "CASE 3"
            }
        }
        
        Button("Update") {
            if case .output_message(var message) = response3.output[0] {
                // Safe: Check for at least one text item
                for idx in message.content.indices {
                    if case .output_text(var textItem) = message.content[idx] {
                        textItem.text += "Hello"
                        message.content[idx] = .output_text(textItem)
                    }
                }
                response3.output[0] = .output_message(message)
            }
        }
    }
}
