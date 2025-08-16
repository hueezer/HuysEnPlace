//
//  ChatView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/7/25.
//

import SwiftUI

struct ChatContainer: View {
    @State private var messages: [Message] = []
    @State private var responses: [Response] = []
    @State private var prompt: String = ""
    @State private var session = OpenAISession(instructions: """
                    # Identity

                    You contain all culinary knowledge in the world.
                    When generating recipes, the unit should always be in metric.
                    """)
    
    @State private var incomingResponse: Response?
    
    var body: some View {
        @Bindable var session = session
        ChatView(responses: $responses, prompt: $prompt, incomingResponse: $incomingResponse) { inputItems in
            Task {

//                if let response = try await session.respondTest(to: message.text, generating: GeneratedMessage.self) {
//                    let message = Message(text: response.text, role: .assistant)
//                    messages.append(message)
//                }
                
//                do {
//                    let _ = try await session.stream(input: inputItems) { text in
//                        incomingMessage = Message(text: "Incoming...", role: .assistant)
//                    } onDelta: { delta in
//                        if let current = incomingMessage {
//                            var updated = current
//                            updated.text += delta
//                            incomingMessage = updated
//                        } else {
//                            print("NO DELTA")
//                            incomingMessage = Message(text: delta, role: .assistant)
//                        }
//                    } onCompleted: { text in
//                        if let current = incomingMessage {
//                            var updated = current
//                            updated.text = text
//                            messages.append(updated)
//                            incomingMessage = nil
//                        }
//                    }
//    //                let streamEvents = try await session.stream(input: input)
//                } catch {
//                    print("Streaming failed:", error)
//                }
            }
        }
        .safeAreaPadding()
    }
}

struct ChatView: View {
    
    @Namespace private var namespace
    
//    @Binding var messages: [Message]
    @Binding var responses: [Response]
    @Binding var prompt: String
    @Binding var incomingResponse: Response?
    
    @State private var scrolledID: Message.ID?
    
    var onSubmit: ([ResponseItem]) -> Void = { _ in }
    
    var body: some View {
        ScrollViewReader { value in
            GlassEffectContainer(spacing: 20) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach($responses) { response in
                            ChatResponseView(response: response)
                        }
                        if let _ = incomingResponse {
                            ChatResponseView(response: Binding(
                                get: { incomingResponse! },
                                set: { incomingResponse = $0 }
                            ))
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrolledID)
//                .onChange(of: messages.count, { old, new in
//                    withAnimation {
//                        if let lastMessageID = messages.last?.id {
//                            value.scrollTo(lastMessageID, anchor: .top)
//                        }
//                    }
//                })
            }
            
            VStack(spacing: 0) {
                TextField("Type your message...", text: $prompt)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .submitLabel(.send)
                    .onSubmit {
                        submitMessage()
                    }
                HStack(spacing: 0) {
                    Spacer()
//                    Button(action: {
//                        withAnimation {
//                            value.scrollTo("BOTTOM", anchor: .top)
//                            let message = Message(text: prompt, role: .user)
//                            messages.append(message)
//                            prompt = ""
//                        }
//                    }, label: {
//                        Label("Submit", systemImage: "arrow.up")
//                    })
//                    .font(.title3)
//                    .buttonStyle(.borderedProminent)
//                    .buttonBorderShape(.circle)
                    
                    Image(systemName: "arrow.up")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .clipped()
                        .clipShape(Circle())
                        .glassEffect(.regular.tint(.blue).interactive())
                        .onTapGesture {
                            submitMessage()
                        }
                }
            }
            .padding(8)
            .glassEffect(in: RoundedRectangle(cornerRadius: 32))
        }
    }
    
//    func submitMessage() {
//        let message = Message(text: prompt, role: .user)
//        messages.append(message)
//        prompt = ""
//        onSubmit(message)
//    }
        func submitMessage() {
//            let message = Message(text: prompt, role: .user)
//            messages.append(message)
//            prompt = ""
            
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
            
//            let response = Response(id: UUID().uuidString, status: .completed, output: inputItems)
            prompt = ""
            onSubmit(inputItems)
        }
}



#Preview {
    @Previewable @State var messages: [Message] = [
        Message(text: "Hi!", role: .user),
        Message(text: "Hello! How can I help you today? I can do so many different things!", role: .assistant),
        Message(text: "What are some good bread recipes? I like banh mi and sourdough.", role: .user),
        Message(text: "Try sourdough or focaccia!", role: .assistant)
    ]
    @Previewable @State var prompt = ""
    @Previewable @State var incomingMessage: Message? = Message(text: "Incoming...", role: .assistant)
    VStack {
//        ChatView(messages: $messages, prompt: $prompt, incomingMessage: $incomingMessage)
//            .safeAreaPadding()
        ChatContainer()
        HStack {
//            Button("Scroll To Top") {
//                if let lastID = messages.last?.id {
//                    value.scrollTo(lastID, anchor: .top)
//                }
//            }
            Button("TEST User", action: {
                withAnimation {
//                    value.scrollTo("BOTTOM", anchor: .top)
                    let message = Message(text: "Testing this message input", role: .user)
                    messages.append(message)
                }
                //                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                //                            value.scrollTo(message.id, anchor: .top)
                //                        }
            })
            Button("TEST Assistant", action: {
                withAnimation {
//                    value.scrollTo("BOTTOM", anchor: .top)
                    messages.append(Message(text: "Testing this message output. This can be a little bit longer. It's actually usually quite a bit longer.", role: .assistant))
                }
            })
            
            Button("TEST INCOMING") {
                incomingMessage = Message(text: "Testing incoming message...", role: .assistant)
            }
        }
    }
}

