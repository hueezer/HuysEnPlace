//
//  CookingView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/25/25.
//

import SwiftUI
import FoundationModels

struct Cooking: Codable {
    var context: String = ""
    
    @Generable(description: "Generate a clear, step-by-step cooking plan. For each step, break down the instructions into simple, actionable tasks. If any step contains too many tasks or seems complex, divide it into additional, smaller steps to maximize clarity and ease of following.")
    struct Plan: Codable {
        @Guide(description: "The title of the recipe or plan. The title should not include the word plan.")
        var title: String = ""
        
        var description: String? = ""
        
        @Guide(description: "Steps for the plan. Not every step should have a table.")
        var steps: [Step] = []
    }
    
    @Generable
    struct Step: Codable {
        @Guide(description: "Direct, actionable instructions for completing this cooking step. Use concise language focused only on what the cook needs to do. Do not include text like Step 1 or 2 etc. Avoid using hyphens or ellipsis.")
        var text: String
        
//        @Guide(description: "Natural-sounding narration of this step, suitable for spoken instructions or voiceover. This should guide the user conversationally through what to do. Avoid using hyphens or ellipsis.")
//        var script: String
        
        @Guide(description: "Set to true if a supplemental table gives essential clarity or presents structured data (like a list ingredients, key times or temperature, or critical context) that cannot be easily or more clearly conveyed in plain text. If the table is redundant, overly simple, or not truly helpful, leave as false. Resist the temptation to always include a table; prefer minimalism unless the table is instrumental for understanding.")
        var includeTable: Bool
        
        @Guide(description: "A supplemental table presenting relevant details for this step, such as ingredients, timings, or contextual data. Use only when structured information enhances clarity; otherwise, set to null.")
        var table: InfoTable?
    }
    
    @Generable
    struct StepInfo: Codable {
        
        @Guide(description: "Topics to go further in depth in this step. This can be tips and tricks, helpful techniques. Order it by most essential first, then to more in depth but unecessary information. Maximum of 10 topics.")
        var topics: [String] = []
    }
    
    @Generable
    struct Message: Codable {
        
        @Guide(description: "The text of the message.")
        var text: String
    }
}

struct CookingView: View {
    
    @State private var session = OpenAI(instructions: "")
    
    // Inputs
    @State private var context: String = ""
    @State private var prompt: String = ""
    
    // Outputs
    @State private var plan: Cooking.Plan.PartiallyGenerated?
//    @State private var currentStep: Cooking.Step.PartiallyGenerated?
    @State private var info: Cooking.StepInfo.PartiallyGenerated?
    @State private var messages: [Cooking.Message] = []
    @State private var currentMessage: Cooking.Message.PartiallyGenerated?
    
    // UI
    @State private var showContext: Bool = false
    @State private var currentStepIndex: Int = 0

    var body: some View {
        ScrollView {
            VStack {
                
//                if let steps = plan?.steps {
//                    ForEach(steps.indices, id: \.self) { index in
//                        let step = steps[index]
//                        Text(step.text ?? "")
//                    }
//                }
                
                if plan != nil, plan?.steps?.count ?? 0 > 0, let currentStep = plan?.steps?[currentStepIndex] {
                    Text(plan?.title ?? "")
                    Text("Text:")
                    Text(currentStep.text ?? "")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .bold()
                        .padding()
                    
                    Text("Include Table: \(currentStep.includeTable)")
                    
                    if currentStep.includeTable ?? false, let partialTable = currentStep.table,
                       let columns = partialTable.columns,
                       let rows = partialTable.rows {
                        TableView(table: InfoTable(columns: columns, rows: rows))
                    }
                    
                    ForEach(info?.topics ?? [], id: \.self) { topic in
                        Text(topic)
                    }
                }
                
                if let currentMessage = currentMessage {
                    Text(currentMessage.text ?? "")
                }
                
                TextField("Prompt", text: $prompt)
                
                Button("Submit") {
                    Task {
                        do {
                            try await sendMessage(prompt)
                            prompt = ""
                        } catch {
                            print("Cooking error: \(error)")
                        }
                    }
                }
            }
        }
        .onAppear {
//            cooking.context = banhMiRecipe.toText()
//            context = banhMiRecipeMarkdown
            context = "Sourdough Bread"
            session = OpenAI(instructions: """
                You are a cooking assistant, guiding the user one step at a time. Start from the beginning of the recipe and give the user clear concise directions. Use a friendly, helpful tone as if you were speaking and guiding the user with your voice.
                <cooking_context>
                \(context)
                </cooking_context>
            """)
            Task {
                try await generatePlan()
            }
        }
        .sheet(isPresented: $showContext) {
            VStack {
                Text("Context")
                    .font(.title2)
                    .bold()
                TextField("Context", text: $context, axis: .vertical)
                if let plan = plan {
                    Text(plan.title ?? "")
                        .font(.title3)
                        .bold()
                    Text(plan.description ?? "")
                    ForEach(plan.steps ?? []) { step in
                        Text(step.text ?? "")
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    showContext.toggle()
                }, label: {
                    Label("Context", systemImage: "richtext.page")
                })
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Next") {
                    if let steps = plan?.steps, currentStepIndex + 1 < steps.count {
                        currentStepIndex += 1
                    }
                }
                .buttonStyle(.glassProminent)
            }
//            ToolbarItem(placement: .primaryAction) {
//                Button("Next") {
//                    Task {
//                        do {
//                            var message = "What should I do next?"
//                            try await sendMessage(message)
//                        } catch {
//                            print("Cooking error: \(error)")
//                        }
//                    }
//                }
//                .buttonStyle(.glassProminent)
//            }
        }
    }
    
    func sendMessage(_ message: String) async throws {

        
        let userMessage = ResponseInputMessageItem(
            id: UUID().uuidString,
            content: [
                .input_text(ResponseInputText(text: message))
            ],
            role: .user,
            type: .message
        )
        let input: [ResponseItem] = [
            .input_message(userMessage)
        ]
        
        var stream = session.streamResponse(input: input, generating: Cooking.Message.self)
        
        for try await partial in stream {
            currentMessage = partial
        }
    }
    
//    func generateInfo() async throws {
//        
//        let userMessage = ResponseInputMessageItem(
//            id: UUID().uuidString,
//            content: [
//                .input_text(ResponseInputText(text: "Generate info for the current cooking step. If the step has ingredients, put the ingredients listed into a table. Current Step:\(currentStep?.text ?? "")"))
//            ],
//            role: .user,
//            type: .message
//        )
//        let input: [ResponseItem] = [
//            .input_message(userMessage)
//        ]
//        
//        var stream = session.streamResponse(input: input, generating: Cooking.StepInfo.self)
//        
//        for try await partial in stream {
//            info = partial
//        }
//    }
    
    func generatePlan() async throws {
        
        let userMessage = ResponseInputMessageItem(
            id: UUID().uuidString,
            content: [
                .input_text(ResponseInputText(text: "Generate a cooking plan for the context. If the context is a recipe, break the recipe up into individual steps. If not, try to generate a plan based on what is there."))
            ],
            role: .user,
            type: .message
        )
        let input: [ResponseItem] = [
            .input_message(userMessage)
        ]
        
        var stream = session.streamResponse(input: input, generating: Cooking.Plan.self)
        
        for try await partial in stream {
            plan = partial
        }
    }
    
//    func generateStep(at index: Int) async throws {
//        let userMessage = ResponseInputMessageItem(
//            id: UUID().uuidString,
//            content: [
//                .input_text(ResponseInputText(text: "Generate details for step #\(index + 1) of the plan."))
//            ],
//            role: .user,
//            type: .message
//        )
//        let input: [ResponseItem] = [
//            .input_message(userMessage)
//        ]
//        var stream = session.streamResponse(input: input, generating: Cooking.Step.self)
//        for try await partial in stream {
//            currentStep = partial
//        }
//    }
}

#Preview {
    NavigationStack {
        CookingView()
    }
}

