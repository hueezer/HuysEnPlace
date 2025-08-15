//
//  ChatResponseView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/15/25.
//

import SwiftUI

struct ChatResponseView: View {
    var response: Response
    @State private var showJSON = false
    var isUser: Bool {
        isUserMessage(response) != nil
    }
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 50)
            }
            VStack(spacing: 16) {
                if let responseInputText = isUserMessage(response) {
                    Text(responseInputText.text)
                    //                    .padding()
                    //                    .background(.indigo.opacity(0.2))
                    //                    .clipped()
                    //                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    //                    .padding()
                    //                    .glassEffect(message.role == .user ? .regular.tint(.blue).interactive() : .regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                    //                    .glassEffectID(message.id, in: namespace)
                    //                    .foregroundStyle(message.role == .user ? .white : .primary)
                    
                } else {
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
            .padding()
            .glassEffect(isUser ? .regular.tint(.blue).interactive() : .regular.interactive(), in: RoundedRectangle(cornerRadius: 32))
            //        .glassEffectID(message.id, in: namespace)
            .foregroundStyle(isUser ? .white : .primary)
            .font(.system(.body, design: .monospaced))
            .onTapGesture {
                showJSON.toggle()
            }
            
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
    @Previewable var response: Response = Response(id: "1", status: .completed, output: [
        .input_message(.init(id: "1", content: [.input_text(.init(text: "Hello"))], role: .user, type: .message))
    ])
    
    @Previewable var response2: Response = Response(id: "2", status: .completed, output: [
        .output_message(.init(id: "2", content: [.output_text(.init(type: .output_text, text: "Hello"))], role: .assistant, status: .completed, type: .message))
    ])
    ChatResponseView(response: response)
    ChatResponseView(response: response2)
}
