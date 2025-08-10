//
//  StreamTestView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/9/25.
//

import SwiftUI

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
    
    @State private var outputText: String = ""
    @State private var status: String = ""
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Stream Test")
                Text("Status: \(status)")
                
                Text("This is regular text.")
                Text("* This is **bold** text, this is *italic* text, and this is ***bold, italic*** text.")
                Text("~~A strikethrough example~~")
                Text("`Monospaced works too`")
                Text("Visit Apple: [click here](https://apple.com)")
                Text(LocalizedStringKey(outputText))
            }
        }
        .task {
            do {
                let _ = try await session.stream(input: "Can you tell me about bread flour? Just the first 200 words is great.") { text in
                    outputText  = text
                } onDelta: { delta in
                    outputText += delta
                } onCompleted: { text in
                    outputText  = text
                }
//                let streamEvents = try await session.stream(input: input)
                status = "Started..."
            } catch {
                print("Streaming failed:", error)
            }

        }
    }
}

#Preview {
    StreamTestView()
}
