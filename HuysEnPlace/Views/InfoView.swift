//
//  InfoView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/16/25.
//

import SwiftUI

struct InfoView: View {
    var subjectName: String
    var context: String
    
    @State private var pageContent: String = ""
    
    @State private var session = OpenAI(instructions: """
        ## Identity

        You contain all culinary knowledge in the world. Produce content that is both interesting, concise and factual. It should be the most interesting written culinary content ever to exist.
        
        ## Format
        Each section should have a title and should be bold.
        Include a new line between the title and the body.
        Sections should be no longer than 5 sentences.
        Italicize any important information that should be emphasized.
        Respond in markdown.
        
        ## Here is the markdown supported:
        This is regular text.
        * This is **bold** text, this is *italic* text, and this is ***bold, italic*** text.
        ~~A strikethrough example~~
        `Monospaced works too`
        
        Only use these supported markdown styles
        """
    )
    
    @State private var isLoading = true
    
    let line1 = (0..<5).map { _ in Int.random(in: 50...90) }
    let line2 = (0..<5).map { _ in Int.random(in: 50...90) }
    let line3 = (0..<5).map { _ in Int.random(in: 50...90) }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(subjectName.capitalized)
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                
                if isLoading {
                    ParagraphLoadingPlaceholder(lines: line1)
                    ParagraphLoadingPlaceholder(lines: line2)
                    ParagraphLoadingPlaceholder(lines: line3)
                }
                
                Text(LocalizedStringKey(pageContent))
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .task {
            let userMessage = ResponseInputMessageItem(
                id: UUID().uuidString,
                content: [
                    .input_text(ResponseInputText(text: """
                    Write some content on the subject: \(subjectName).
                    Write in within the context of: \(context)
                """))
                ],
                role: .developer,
                status: .in_progress,
                type: .message
            )
            let input: [ResponseItem] = [
                .input_message(userMessage)
            ]
            
            do {
                let streamEvents = try await session.stream(input: input)
                for try await streamEvent in streamEvents {
                    switch streamEvent {
                        
                    case .responseCreatedEvent(let event):
                        print("responseCreated: \(event.response)")
                        
                        if let text = event.response.output_text {
                            pageContent = text
                        }
                    case .responseCompletedEvent(let event):
                        print("responseCreated: \(event.response.output)")
                        for item in event.response.output {
                            switch item {
                            case .output_message(let message):
                                print("output_message: \(message)")
                                for content in message.content {
                                    switch content {
                                    case .output_text(let outputTextItem):
                                        pageContent = outputTextItem.text
                                    default:
                                        print("Default")
                                    }
                                }
                            default:
                                print("Default")
                            }
                        }
                    case .responseOutputTextDeltaEvent(let event):
                        print("responseOutputTextDeltaEvent: \(event)")
                        if isLoading {
                            isLoading = false
                        }
                        pageContent += event.delta
                        
                    case .responseFunctionCallArgumentsDoneEvent(let event):
                        print("responseFunctionCallArgumentsDoneEvent: \(event)")
                    default:
                        print("RecipeIngredientInfoView unhandled event: \(streamEvent)")
                    }
                    
                }
            } catch {
                print("Streaming failed:", error)
            }

        }
    }
}

struct ParagraphLoadingPlaceholder: View {
    // Using an array and map:
    let lines: [Int]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 96, height: 18)
                .padding(.bottom, 8)
            VStack(alignment:.leading) {
                ForEach(lines, id: \.self) { barWidths in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 18)
                        .containerRelativeFrame(.horizontal, count: 100, span: barWidths, spacing: 0)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        InfoView(subjectName: "Ascorbic Acid", context: "This is being used in a banh mi recipe.")
    }
}
