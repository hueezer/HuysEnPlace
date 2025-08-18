//
//  RecipeView2.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/8/25.
//

import SwiftUI

struct RecipeView: View {
    @State var editMode: EditMode = .inactive
    @Environment(\.fontResolutionContext) var fontResolutionContext
    var recipe: Recipe
    @State var selection = AttributedTextSelection()
    @State var showIngredients: Bool = false
    
    @State var ingredients: [Ingredient] = allIngredients
    
    @State var ingredientQuantityDetails: IngredientQuantity?
    @State var editingIngredientList: IngredientList?
    
    @Environment(\.self) private var environment
    
    @State private var shareJsonUrl: URL?
    
    @State private var modifiedRecipe: Recipe?
    
    @State private var showChat: Bool = false
    @State private var showMinimizedChat: Bool = false
    @State private var minimizedChatResponse: Response?
    @State private var shouldShowMinimizedChatActions: Bool = false
    @State private var showMinimizedChatActions: Bool = false
    
    @Namespace private var namespace
    
    // Chat
    @State private var responses: [Response] = []
    @State private var incomingResponse: Response?
    @State private var prompt: String = ""
    @State private var faq: [String] = [
        "Can I skip or substitute ascorbic acid?",
        "Do I really need lava rocks?",
        "Can I make this without a stand mixer?",
        "can replace the egg in the recipe?",
        "Why is the salt so low? Can I increase it?"
    ]

    @State private var session = OpenAI(instructions: "")

    var body: some View {
        @Bindable var recipe = recipe
        VStack {
            if let url = shareJsonUrl {
                VStack {
                    ShareLink("Share URL", item: url)
                }
            }
            
//            TextEditor(text: $recipe.content, selection: $selection)
//                .contentMargins(.horizontal, 12.0, for: .scrollContent)
//                .textEditorStyle(.plain)

            ScrollView {
                LazyVStack(pinnedViews: .sectionHeaders) {
                    if modifiedRecipe == nil {
                        VStack(alignment: .center, spacing: 16) {
                            Text(recipe.title)
                                .font(.title)
                                .bold()
                                .multilineTextAlignment(.center)
                            
                            Text("Ingredients")
                                .font(.headline)
                            
                            if editMode == .active {
                                HStack {
                                    Button(action: {
                                        recipe.ingredients.append(IngredientList(title: "", items: []))
                                        if let lastIngredientList = recipe.ingredients.last {
                                            editingIngredientList = lastIngredientList
                                        }
                                    }) {
                                        Label("Ingredients", systemImage: "plus")
                                    }
                                    .buttonStyle(.glassProminent)
                                }
                            }
                            
                            ForEach($recipe.ingredients) { $list in
                                IngredientListView(list: $list, onTapIngredient: { ingredientQuantity in
                                    ingredientQuantityDetails = ingredientQuantity
                                }, onTapList: { list in
                                    editingIngredientList = $list.wrappedValue
                                })
                                .shadow(color: editMode == .active ? .blue : .clear, radius: 0)
                                .environment(\.editMode, $editMode)
                            }
                            
                            Text("Steps")
                                .font(.headline)
                            
                            ForEach(Array(zip(recipe.steps.indices, $recipe.steps)), id: \.1.id) { index, $step in
                                StepView(index: index, step: $step)
                                    .environment(recipe)
                                    .shadow(color: editMode == .active ? .blue : .clear, radius: 0)
                            }
                            
                            if editMode == .active {
                                HStack {
                                    Button(action: {
                                        recipe.steps.append(.init())
                                    }) {
                                        Label("Add Step", systemImage: "plus")
                                    }
                                    .buttonStyle(.glassProminent)
                                }
                            }
                        }
                    } else {
                        RecipeDiffView(recipe: recipe, updatedRecipe: $modifiedRecipe)
                    }
                }
                
            }
            .contentMargins(.horizontal, 12.0, for: .scrollContent)

        }
        .overlay(alignment: .top) {
            if showMinimizedChat, let response = minimizedChatResponse {
                VStack(spacing: 16) {
                    ForEach(response.output) { item in
                        switch item {
                        case .output_message(let message):
                            ForEach(message.content.indices, id: \.self) { idx in
                                let content = message.content[idx]
                                
                                if case .output_text(let text) = content {
                                    Text(LocalizedStringKey(text.text))
                                }
                            }
                        default:
                            EmptyView()
                        }
                    }
                    
                    if showMinimizedChatActions {
                        HStack(spacing: 16) {
                            Button("Reject") {
                                withAnimation {
                                    self.modifiedRecipe = nil
                                    resetChatDefaults()
                                }
                            }
                            .tint(.red)
                            .buttonStyle(.borderedProminent)
                            
                            Button("Accept") {
                                withAnimation {
                                    if let modifiedRecipe = modifiedRecipe {
                                        recipe.title = modifiedRecipe.title
                                        recipe.ingredients = modifiedRecipe.ingredients
                                        recipe.steps = modifiedRecipe.steps
                                        self.modifiedRecipe = nil
                                        resetChatDefaults()
                                    }
                                    
                                }
                            }
                            .tint(.green)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                }
                .padding()
                
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 32))
                .safeAreaPadding(.horizontal)
                .onTapGesture {
                    minimizedChatResponse = nil
                    showMinimizedChat = false
                    showChat.toggle()
                }
            }
        }
//        .attributedTextFormattingDefinition(
//            RecipeFormattingDefinition(ingredients: Set(ingredients.map(\.id)))
//        )
        .onAppear {
            recipe.content = banhMiRecipeContent
            
            let modifyRecipeTool = ModifyRecipeTool(onCall: { generatedRecipe in
                Task { @MainActor in
                    print("ON CALL RECIPE: \(generatedRecipe.title)")
                    print("generatedRecipe: \(generatedRecipe)")
                    showChat = false
                    showMinimizedChat = true
                    minimizedChatResponse = Response(id: UUID().uuidString, status: .in_progress, output: [.output_message(.init(id: UUID().uuidString, content: [.output_text(.init(type: .output_text, text: ""))], role: .assistant, status: .in_progress, type: .message))])
                    shouldShowMinimizedChatActions = true
                    withAnimation {
                        modifiedRecipe = Recipe(from: generatedRecipe)
                    }
                }
            })
            
            session = OpenAI(
                tools: [
                    .modifyRecipe(modifyRecipeTool)
                ],
                instructions: """
                    Help the user with any questions related to this recipe. Be very concise.
                    <context_gathering>
                    Goal: Get enough context fast. Parallelize discovery and stop as soon as you can act.

                    Method:
                    - Start broad, then fan out to focused subqueries.
                    - In parallel, launch varied queries; read top hits per query. Deduplicate paths and cache; don’t repeat queries.
                    - Avoid over searching for context. If needed, run targeted searches in one parallel batch.

                    Early stop criteria:
                    - You can name exact content to change.
                    - Top hits converge (~70%) on one area/path.

                    Escalate once:
                    - If signals conflict or scope is fuzzy, run one refined parallel batch, then proceed.

                    Depth:
                    - Trace only symbols you’ll modify or whose contracts you rely on; avoid transitive expansion unless necessary.

                    Loop:
                    - Batch search → minimal plan → complete task.
                    - Search again only if validation fails or new unknowns appear. Prefer acting over more searching.
                    </context_gathering>
                    \(banhMiRecipe.toText())
                    """
            )
        }
        .sheet(isPresented: $showChat) {
            ChatView(responses: $responses, prompt: $prompt, incomingResponse: $incomingResponse, faq: $faq) { inputItems in
                print("ON SUBMIT INPUT ITEMS: \(inputItems)")
                Task {
                    do {
                        let response = Response(id: UUID().uuidString, status: .completed, output: inputItems)
                        responses.append(response)
                        
                        let stream = try await session.stream(input: inputItems)
                        try await handleStream(stream)
                    } catch {
                        print("Streaming failed:", error)
                    }
                }
            }
            .safeAreaPadding()
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $ingredientQuantityDetails) { ingredientQuantity in
            RecipeIngredientInfoView(recipe: recipe, ingredientQuantity: ingredientQuantity)
                .presentationDetents([.fraction(0.6), .large])
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                
                Button("Test") {
                    modifiedRecipe = banhMiRecipeDiff
                }
                
                if editMode.isEditing {
                    Button("Save", systemImage: "checkmark") {
                        withAnimation {
                            editMode = .inactive
                        }
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                
                Menu("Options", systemImage: "line.3.horizontal") {
                    Button("Edit", systemImage: "pencil") {
                        withAnimation {
                            if editMode.isEditing {
                                editMode = .inactive
                            } else {
                                editMode = .active
                            }
                        }
                    }

                    Button("Share", systemImage: "square.and.arrow.up") {
                        if let json = recipe.toJson() {
                            let url = FileManager.default.temporaryDirectory
                                           .appendingPathComponent("Recipe.json")
                            try? json.write(to: url, atomically: true, encoding: .utf8)
                            shareJsonUrl = url
                        }
                    }
                    Menu("Copy") {
                        Button("Copy", action: {
                            
                        })
                        Button("Copy Formatted", action: {
                            
                        })
                        Button("Copy Library Path", action: {
                            
                        })
                    }
                }
                
            }
            
            ToolbarSpacer(placement: .topBarLeading)
            
            ToolbarItem(placement: .topBarLeading) {
                
                Menu("Common Variations", systemImage: "arrow.trianglehead.branch") {
                    Section("\(recipe.title) Variations") {
                        Button {
                            do {
                                let r = try Recipe.fromJsonFile(name: "recipe31")
                                recipe.title = r.title
                                recipe.content = r.content
                                recipe.ingredients = r.ingredients
                                recipe.steps = r.steps
                            } catch {
                                print("Error loading recipe.")
                            }
                        } label: {
                            Text("Banh Mi Bread")
                            Text("The original recipe")
                        }
                        
                        Button {
                            do {
                                let r = try Recipe.fromJsonFile(name: "BanhMiNoAscorbicAcid")
                                recipe.title = r.title
                                recipe.content = r.content
                                recipe.ingredients = r.ingredients
                                recipe.steps = r.steps
                            } catch {
                                print("Error loading recipe.")
                            }
                        } label: {
                            Text("Without Ascorbic Acid")
                        }
                        
                        Button {
                            // Rename action.
                        } label: {
                            Text("Without Lava Rocks")
                        }
                    }
                    
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {

                if editMode.isEditing {
                    Button("Autotag", systemImage: "wand.and.sparkles.inverse") {
                        let nameString = "Bake"
                        let ranges = RangeSet(self.recipe.content.characters.ranges(of: Array(nameString)))
                        let newIngredient = Ingredient(id: "new-\(nameString)", name: .init(nameString))
                        ingredients.append(newIngredient)
                        recipe.content.transform(updating: &self.selection) { text in
                            //                        text[ranges].ingredient = "new-\(nameString)"
                            //                        text[ranges].link = .init(string: "miseenplace://ingredients/\(newIngredient.id)")
                            text[ranges].foregroundColor = .red
                            
                        }
                    }
                    
                    Button("Ingredient", systemImage: "carrot") {
                        showIngredients.toggle()
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showChat.toggle()
                }, label: {
                    Label("Chat", systemImage: "message")
                })
                .buttonStyle(.glassProminent)
                
            }
            
        }
        .toolbarBackground(.blue, for: .bottomBar)
        
//        .onAppear {
//            showMinimizedChat = true
//            minimizedChatResponse = Response(id: "2", status: .completed, output: [
//                .output_message(.init(id: "2", content: [.output_text(.init(type: .output_text, text: "Ascorbic acid removed; all other quantities and steps stay the same."))], role: .assistant, status: .completed, type: .message))
//            ])
//            
//        }
        
//        .task {
//            do {
//                let r = try Recipe.fromJsonFile(name: "recipe31")
//                recipe.title = r.title
//                recipe.content = r.content
//                recipe.ingredients = r.ingredients
//                recipe.steps = r.steps
//            } catch {
//                print("Error loading recipe.")
//            }
//        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .environment(\.editMode, $editMode)
    }
    
    func selectionIsEmpty() -> Bool {
        let indices = selection.indices(in: recipe.content)
        switch indices {
            
        case .insertionPoint(_):
            return true
        case .ranges(_):
            return false
        }
    }
    
    func autotag(ingredients: [Ingredient]) {
        
    }
    
    func autotag(ingredient: Ingredient) {
        let nameString = ingredient.name
        let ranges = RangeSet(self.recipe.content.characters.ranges(of: Array(nameString)))
        recipe.content.transform(updating: &self.selection) { text in
            text[ranges].ingredient = ingredient.id
            text[ranges].link = .init(string: "miseenplace://ingredients/\(ingredient.id)")
            text[ranges].foregroundColor = .red
        }
    }
    
    func handleStream(_ stream: AsyncThrowingStream<ResponseStreamEvent, Error>) async throws {
        for try await streamEvent in stream {
            switch streamEvent {
                
            case .responseCreatedEvent(let event):
                incomingResponse = event.response
            case .responseOutputItemAddedEvent(let event):
                incomingResponse?.output.append(event.item)
            case .responseContentPartAddedEvent(let event):
                if case .output_message(var outputMessage) = incomingResponse?.output[event.output_index] {
                    outputMessage.content.append(event.part)
                    incomingResponse?.output[event.output_index] = .output_message(outputMessage)
                }
            case .responseOutputTextDeltaEvent(let event):
                guard var response = incomingResponse, response.output.indices.contains(event.output_index) else { break }
                
                var responseItem = response.output[event.output_index]
                if case .output_message(var message) = responseItem {
                    if message.content.indices.contains(event.content_index) {
                        var content = message.content[event.content_index]
                        if case .output_text(var outputText) = content {
                            outputText.text += event.delta
                            content = .output_text(outputText)
                            message.content[event.content_index] = content
                            responseItem = .output_message(message)
                            response.output[event.output_index] = responseItem
                            response.id = UUID().uuidString
                            incomingResponse = response
                            
                            if showMinimizedChat {
                                minimizedChatResponse = response
                                
                            }
                        }
                    }
                }
            case .responseCompletedEvent(let event):
                incomingResponse = nil
                responses.append(event.response)
                
                if shouldShowMinimizedChatActions {
                    withAnimation {
                        showMinimizedChatActions = true
                    }
                }

            default:
                print("UNHANDLED responseStreamEvent: \(streamEvent)")
            }
        }
    }
    
    func resetChatDefaults() {
        showChat = false
        showMinimizedChat = false
        minimizedChatResponse = nil
        shouldShowMinimizedChatActions = false
        showMinimizedChatActions = false
    }
}

#Preview {
    @Previewable @State var recipe = banhMiRecipe
    NavigationStack {
        RecipeView(recipe: recipe)
//        RecipeView2(recipe: recipe)
//            .task {
//                recipe.title = "Loading..."
//                do {
//                    let r = try Recipe.fromJsonFile(name: "recipe1")
//                    print("LOADED HERE 1 \(r.content)")
//                    recipe.title = "Successfully loaded"
//                    recipe.content = r.content
//                } catch {
//                    print("Error loading recipe.")
//                    recipe.title = "Failed to load"
//                }
//            }
    }
    .environment(\.editMode, .constant(.inactive))
}

extension AttributedString {
    init(styledMarkdown markdownString: String) throws {
        var output = try AttributedString(
            markdown: markdownString,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            ),
            baseURL: nil
        )

        for (intentBlock, intentRange) in output.runs[AttributeScopes.FoundationAttributes.PresentationIntentAttribute.self].reversed() {
            guard let intentBlock = intentBlock else { continue }
            for intent in intentBlock.components {
                switch intent.kind {
                case .header(level: let level):
                    switch level {
                    case 1:
                        output[intentRange].font = .system(.title).bold()
                    case 2:
                        output[intentRange].font = .system(.title2).bold()
                    case 3:
                        output[intentRange].font = .system(.title3).bold()
                    default:
                        break
                    }
                default:
                    break
                }
            }
            
            if intentRange.lowerBound != output.startIndex {
                output.characters.insert(contentsOf: "\n", at: intentRange.lowerBound)
            }
        }

        self = output
    }
}

