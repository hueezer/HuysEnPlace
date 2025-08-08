//
//  ChatView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/7/25.
//

import SwiftUI

struct ChatContainer: View {
    @State private var messages: [Message] = []
    @State private var prompt: String = ""
    var body: some View {
        ChatView(messages: $messages, prompt: $prompt)
            .safeAreaPadding()
    }
}

struct ChatView: View {
    @Binding var messages: [Message]
    @State private var scrolledID: Message.ID?
    @Binding var prompt: String
    @Namespace private var namespace
    var body: some View {
        ScrollViewReader { value in
            GlassEffectContainer(spacing: 20) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            HStack(spacing: 0) {
                                if message.role == .user {
                                    Spacer(minLength: 50)
                                }
                                Text("\(message.text)")
                                    .padding()
                                    .glassEffect(message.role == .user ? .regular.tint(.blue).interactive() : .regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                                    .glassEffectID(message.id, in: namespace)
                                    .foregroundStyle(message.role == .user ? .white : .primary)
                                if message.role == .assistant {
                                    Spacer(minLength: 0)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .id(message.id)
                            //                        .frame(minHeight: messages.last?.id == message.id ? 400 : 0, alignment: .top)
                            
                        }
                        VStack {
                            
                        }
                        .frame(height: 800)
                        .id("BOTTOM")
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrolledID)
                .onChange(of: messages.count, { old, new in
                    withAnimation {
                        if let lastMessageID = messages.last?.id {
                            value.scrollTo(lastMessageID, anchor: .top)
                        }
                    }
                })
            }
            
            VStack(spacing: 0) {
                TextField("Type your message...", text: $prompt)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .submitLabel(.send)
                    .onSubmit {
                        withAnimation {
                            value.scrollTo("BOTTOM", anchor: .top)
                            let message = Message(text: prompt, role: .user)
                            messages.append(message)
                            prompt = ""
                        }
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
                            withAnimation {
                                value.scrollTo("BOTTOM", anchor: .top)
                                let message = Message(text: prompt, role: .user)
                                messages.append(message)
                                prompt = ""
                            }
                        }
                }
            }
            .padding(8)
            .glassEffect(in: RoundedRectangle(cornerRadius: 32))
        }
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
    VStack {
        ChatView(messages: $messages, prompt: $prompt)
            .safeAreaPadding()
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
        }
    }
}
