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
        var title: String? = ""
        
        var description: String? = ""
        
        @Guide(description: "Steps for the plan. Not every step should have a table.")
        var steps: [Step] = []
    }
    
    @Generable
    struct Step: Codable {
        @Guide(description: "Direct, actionable instructions for completing this cooking step. Use concise language focused only on what the cook needs to do. Do not include text like Step 1 or 2 etc. Avoid using hyphens or ellipsis.")
        var text: String? = ""
        
//        @Guide(description: "Natural-sounding narration of this step, suitable for spoken instructions or voiceover. This should guide the user conversationally through what to do. Avoid using hyphens or ellipsis.")
//        var script: String
        
        @Guide(description: "Set to true if a supplemental table gives essential clarity or presents structured data (like a list ingredients, key times or temperature, or critical context) that cannot be easily or more clearly conveyed in plain text. If the table is redundant, overly simple, or not truly helpful, leave as false. Resist the temptation to always include a table; prefer minimalism unless the table is instrumental for understanding.")
        var includeTable: Bool?
        
        @Guide(description: "A supplemental table presenting relevant details for this step, such as ingredients, timings, or contextual data. Use only when structured information enhances clarity; otherwise, set to null.")
        var table: InfoTable?
        
        @Guide(description: "Leave this empty")
        var tips: [Tip] = []
    }
    
    @Generable(description: "A single tip or trick that would be helpful in this step. This can also be general information related to the cuisine or food science that goes more in depth.")
    struct Tip: Codable, Hashable {
        
        @Guide(description: "A short 1-3 word title for the tip.")
        var title: String? = ""
        
        @Guide(description: "The text of the tip.")
        var text: String? = ""
        
        @Guide(description: """
        1) The section’s sole purpose is to compare items side-by-side, AND
        2) There are 2–6 columns with clear comparable attributes (e.g., spec, metric, measurement), AND
        3) There are ≥3 rows (i.e., multiple items being compared), AND
        4) At least 70% of the cells are short numeric/spec values (numbers, units, yes/no, version tags).

        If a table is used, ensure the section title contains a comparison cue like “Comparison,” “Specs,” or “Matrix.”
        """)
        var table: InfoTable?
    }
    
//    @Generable
//    struct StepInfo: Codable {
//
//        @Guide(description: "Topics to go further in depth in this step. This can be tips and tricks, helpful techniques. Order it by most essential first, then to more in depth but unecessary information. Maximum of 10 topics.")
//        var topics: [String] = []
//    }
    
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
//    @State private var info: Cooking.StepInfo.PartiallyGenerated?
    @State private var messages: [Cooking.Message] = []
    @State private var currentMessage: Cooking.Message.PartiallyGenerated?
    @State private var moreInfo: GeneratedInfo.PartiallyGenerated?
    
    
    // UI
    @State private var showContext: Bool = false
    @State private var currentStepIndex: Int = 0
    @State private var cookingError: String? = nil

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(plan?.steps ?? []) { step in
                    CookingStepView(step: step)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .containerRelativeFrame(.horizontal)
                }
                
                if cookingError == nil && plan == nil {
                    VStack {
                        ProgressView()
                            
                    }
                    .containerRelativeFrame(.horizontal)
                }
                
                if let cookingError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text(cookingError)
                            .font(.title3)
                            .bold()
                    }
                    .containerRelativeFrame(.horizontal)
                    .foregroundStyle(.red.gradient)
                }
            }
            .scrollTargetLayout()
        }
        .navigationTitle("My Recipe")
        .toolbarTitleDisplayMode(.inlineLarge)
        .scrollTargetBehavior(.paging)
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
                do {
                    try await generatePlan()
                } catch {
                    print("ERROR GENERATING PLAN")
                    cookingError = "Oops, something went wrong."
                }
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
        .toolbar(id: "main-toolbar") {
            ToolbarItem(id: "tag") {
               Text("hey")
            }
            ToolbarItem(id: "share") {
               Text("yo")
            }
            ToolbarSpacer(.fixed)
            ToolbarItem(id: "more") {
               Text("okay")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    showContext.toggle()
                }, label: {
                    Label("Context", systemImage: "richtext.page")
                })
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    
                }, label: {
                    Label("Chat", systemImage: "square.3.layers.3d.top.filled")
                })
                .buttonStyle(.glassProminent)
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    
                }, label: {
                    Label("Chat", systemImage: "message")
                })
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

struct CookingStepView: View {
    var step: Cooking.Step.PartiallyGenerated
    
    @State private var tips: [Cooking.Tip] = []
    @State private var currentTip: Cooking.Tip.PartiallyGenerated?
    @State private var showTipIsGenerating: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                
                Text(step.text ?? "")
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if step.includeTable ?? false, let partialTable = step.table,
                   let columns = partialTable.columns,
                   let rows = partialTable.rows {
                    TableView(table: InfoTable(columns: columns, rows: rows))
                }

                
                ForEach(tips, id: \.self) { tip in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tip.title ?? "")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        
                        Text(tip.text ?? "")
                            .font(.system(size: 16, weight: .regular, design: .rounded))

                        if let table = tip.table {
                            let columns = table.columns
                            let rows = table.rows
                            TableView(table: InfoTable(columns: columns, rows: rows))
                        }
                    }
                }
                if showTipIsGenerating {
                    Text("Generating Tip...")
                        .frame(height: 50)
                }
                
                
                if let tip = currentTip {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tip.title ?? "")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        
                        Text(tip.text ?? "")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                        
                        if let table = tip.table, let columns = table.columns, let rows = table.rows {
                            TableView(table: InfoTable(columns: columns, rows: rows))
                        }
                    }
                }
                
                
            }
            .safeAreaPadding()
            .rotationEffect(.degrees(180))
        }
        .rotationEffect(.degrees(180))
        .refreshable {
            Task {
                try await generateTip()
            }
        }
    }
    
    func generateTip() async throws {
        print("Generating Tip...")
        showTipIsGenerating = true
        
        var session = OpenAI(instructions: """
            You are a cooking assistant, guiding the user one step at a time. The user is currently on this step:
            \(step.text)
            Here are the tips already included:
            \(tips.map { "\($0.title) \($0.text)" })
        """)
        
        let userMessage = ResponseInputMessageItem(
            id: UUID().uuidString,
            content: [
                .input_text(ResponseInputText(text: "Generate a help tip, technique or relevant supplementary information."))
            ],
            role: .user,
            type: .message
        )
        let input: [ResponseItem] = [
            .input_message(userMessage)
        ]
        
        let stream = session.streamResponse(input: input, generating: Cooking.Tip.self)
        
        for try await partial in stream {
            if showTipIsGenerating {
                showTipIsGenerating = false
            }
            currentTip = partial
        }
        
        let newTip = Cooking.Tip(
            title: currentTip?.title,
            text: currentTip?.text,
            table: InfoTable(
                columns: currentTip?.table?.columns ?? [],
                rows: currentTip?.table?.rows ?? []
            )
        )
        tips.append(newTip)
        currentTip = nil
    }
}

#Preview {
    NavigationStack {
        CookingView()
    }
}

