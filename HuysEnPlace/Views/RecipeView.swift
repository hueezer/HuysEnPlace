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
    
    
    @State private var showModifyChat: Bool = false
    @State private var modifyRecipeMessage: String = ""
    
    @State private var modifiedRecipe: Recipe?
    @State private var modifyRecipeResponse: GeneratedRecipeResponse?
    @State private var updateRecipeIsGenerating: Bool = false
    
    @State private var showChat: Bool = false
    @State private var showMinimizedChat: Bool = false
    @State private var minimizedChatResponse: Response?
    
    @Namespace private var namespace
    
    @State private var previousResponseid: String? = nil
    
    // Chat
    @State private var messages: [Message] = []
    @State private var responses: [Response] = []
    @State private var prompt: String = ""

    
    @State private var incomingMessage: Message?
    
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
                    Section {
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
                            Button(action: {
                                withAnimation {
//                                                showRecipeDiff = false
                                    if let modifiedRecipe = modifiedRecipe {
                                        showModifyChat = false
                                        recipe.title = modifiedRecipe.title
                                        recipe.ingredients = modifiedRecipe.ingredients
                                        recipe.steps = modifiedRecipe.steps
                                        self.modifiedRecipe = nil
                                    }
                                    
                                }
                            }, label: {
                                Label("Apply", systemImage: "checkmark")
                            })
                            .buttonStyle(.glassProminent)
                            .tint(.blue)
                            RecipeDiffView(recipe: recipe, updatedRecipe: $modifiedRecipe)
                        }
                    } header: {
                        if showModifyChat {
                            VStack {
                                
                                if let modifiedRecipe = modifiedRecipe {
                                    if let response = modifyRecipeResponse {
                                        Text(response.message)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                                            
                                    }
                                    
                                    HStack {
                                        Button(action: {
                                            withAnimation {
//                                                showRecipeDiff = false
                                                showModifyChat = false
                                                self.modifiedRecipe = nil
                                                
                                            }
                                        }, label: {
                                            Label("Cancel", systemImage: "xmark")
                                        })
                                        .buttonStyle(.glass)
                                        .tint(.red)
                                        
                                        
                                        Button(action: {
                                            withAnimation {
                                                print("Applying this recipe: \(modifiedRecipe.steps)")
                                                
//                                                showRecipeDiff = false
                                                showModifyChat = false
                                                recipe.title = modifiedRecipe.title
                                                recipe.ingredients = modifiedRecipe.ingredients
                                                recipe.steps = modifiedRecipe.steps
                                                self.modifiedRecipe = nil
                                                
                                            }
                                        }, label: {
                                            Label("Apply", systemImage: "checkmark")
                                        })
                                        .buttonStyle(.glassProminent)
                                        .tint(.blue)
                                    }
                                } else {
                                    TextField("How would you change this recipe?", text: $modifyRecipeMessage, axis: .vertical)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1...10)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .disabled(updateRecipeIsGenerating)
                                    
                                    Button(action: {
                                        Task {
//                                            showRecipeDiff = true
                                            updateRecipeIsGenerating = true
                                            
                                            let fullPrompt = modifyRecipeMessage
                                            
                                            var modifyRecipeTool = ModifyRecipeTool(onCall: { generatedRecipe in
                                                Task { @MainActor in
                                                    print("ON CALL RECIPE: \(generatedRecipe.title)")
                                                    print("generatedRecipe: \(generatedRecipe)")
                                                    withAnimation {
                                                        modifiedRecipe = Recipe(from: generatedRecipe)
                                                    }
                                                }
                                            })

                                            let session = OpenAISession(
                                                tools: [
                                                    .modifyRecipe(modifyRecipeTool)
                                                ],
                                                instructions: """
                                                    # Identity

                                                    You contain all culinary knowledge in the world.
                                                    When generating recipes, the unit should always be in metric.
                                                
                                                    # Current Recipe
                                                    The user is currently viewing this recipe:
                                                    \(recipe.toJson())
                                                """
                                            )
                                            
//                                            let message = try? await session.respondTest(to: fullPrompt, generating: GeneratedMessage.self)
//                                            
//                                            print("HERE IS message: ", message)
                                            
                                            let _ = try await session.stream(input: fullPrompt) { text in
//                                                incomingMessage = Message(text: "Incoming...", role: .assistant)
                                            } onDelta: { delta in
                                                print("onDelta: \(delta)")
//                                                if let current = incomingMessage {
//                                                    var updated = current
//                                                    updated.text += delta
//                                                    incomingMessage = updated
//                                                } else {
//                                                    print("NO DELTA")
//                                                    incomingMessage = Message(text: delta, role: .assistant)
//                                                }
                                            } onCompleted: { text in
                                                print("onComplete: \(text)")
//                                                if let current = incomingMessage {
//                                                    var updated = current
//                                                    updated.text = text
//                                                    messages.append(updated)
//                                                    incomingMessage = nil
//                                                }
                                            }

                                            modifyRecipeMessage = ""
                                            
                                            updateRecipeIsGenerating = false
            //                                showModifyChat = false
                                        }
                                    }, label: {
                                        Label(updateRecipeIsGenerating ? "Thinking..." : "Modify", systemImage: "sparkles")
                                        
                                    })
                                    .buttonStyle(.glassProminent)
                                    .symbolEffect(.rotate, isActive: updateRecipeIsGenerating)
                                }
                            
                                
                            }
                            .padding()
                            .frame(minHeight: 160)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 32))
                            .padding(10)
                        }
                    }
                }
                
            }
            .contentMargins(.horizontal, 12.0, for: .scrollContent)

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
                    showMinimizedChat = true
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
                    \(banhMiRecipe.toText())
                    """
            )
        }
        .sheet(isPresented: $showChat) {
            ChatView(responses: $responses, prompt: $prompt, incomingMessage: $incomingMessage) { inputItems in
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
        .sheet(isPresented: $showIngredients) {
            let name = self.recipe.content[selection]
            let nameString = String(name.characters)
            ForEach(ingredients) { ingredient in
                HStack {
                    Text("\(ingredient.name)")
                    
                    Button(action: {
//                        let ranges = RangeSet(self.recipe.content.characters.ranges(of: name.characters))
//                        recipe.content.transform(updating: &self.selection) { text in
//                            print("text ranges: \(text[ranges])")
//                            print("ingredient id: \(ingredient.id)")
//                            text[ranges].ingredient = ingredient.id
//                            text[ranges].link = .init(string: "miseenplace://ingredients/\(ingredient.id)")
//                            text[ranges].foregroundColor = .red
////                            text[ranges]
//                        }
//                        showIngredients = false
                        autotag(ingredient: ingredient)
                        showIngredients = false
                    }, label: {
                        Text("Ingredient And Link")
                    })
                }
                .buttonStyle(.bordered)
            }
            
            Button(action: {
                let ranges = RangeSet(self.recipe.content.characters.ranges(of: name.characters))
                let newIngredient = Ingredient(id: "new-\(nameString)", name: .init(nameString))
                ingredients.append(newIngredient)
                recipe.content.transform(updating: &self.selection) { text in
                    print("text ranges: \(text[ranges])")
//                    print("ingredient id: \(ingredient.id)")
                    text[ranges].ingredient = "new-\(nameString)"
                    text[ranges].link = .init(string: "miseenplace://ingredients/\(newIngredient.id)")
                }
                
                showIngredients = false
                
            }, label: {
                Text(nameString)
            })
        }
        .sheet(item: $ingredientQuantityDetails) { ingredientQuantity in
            RecipeIngredientInfoView(recipe: recipe, ingredientQuantity: ingredientQuantity)
                .presentationDetents([.fraction(0.6), .large])
        }
        .sheet(item: $editingIngredientList) { list in
            if let listIndex = recipe.ingredients.firstIndex(where: { $0.id == list.id }) {
                IngredientListEditor(list: $recipe.ingredients[listIndex])
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                
                Button("Modify", systemImage: "square.and.pencil") {
                    withAnimation {
                        showModifyChat.toggle()
                    }
                }
                .tint(.blue)
                .buttonStyle(.glassProminent)
                
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
            
            ToolbarItem(placement: .bottomBar) {
                if showMinimizedChat, let response = minimizedChatResponse {
                    VStack {
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
                    }
                    .padding(8)
                    
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
//                    .glassEffect(in: RoundedRectangle(cornerRadius: 32))
                    .onTapGesture {
                        minimizedChatResponse = nil
                        showMinimizedChat = false
                        showChat.toggle()
                    }
                } else {
                    Button(action: {
                        showChat.toggle()
                    }, label: {
                        Label("Chat", systemImage: "message")
                    })
                    .buttonStyle(.glassProminent)
                }

            }
            
        }
        .toolbarBackground(.blue, for: .bottomBar)
        .onAppear {
            showMinimizedChat = true
            minimizedChatResponse = Response(id: "2", status: .completed, output: [
                .output_message(.init(id: "2", content: [.output_text(.init(type: .output_text, text: "Ascorbic acid removed; all other quantities and steps stay the same."))], role: .assistant, status: .completed, type: .message))
            ])
            
        }
        
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
    
//    private func handleURL(_ url: URL) {
//        // Any side effect you need—navigation, async task, analytics, …
//        print("Link tapped:", url.absoluteString)
//        if let host = url.host() {
//            if host == "ingredients" {
//                print("Tapped Ingredients")
//                print("path components last: \(url.pathComponents.last)")
//                if let pathId = url.pathComponents.last, let ingredient = ingredients.first(where: { $0.id == pathId }) {
//                    ingredientInfo = ingredient
//                } else {
//                    print("DID NOT FIND INGREDIENT")
//                }
//            }
//        }
//    }
    
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
//            print("Received event: \(streamEvent)")
//            currentEvent = streamEvent
//            events.append(streamEvent)
            switch streamEvent {
                
//            case .responseCreatedEvent(let event):
//                currentResponse = event.response
//            case .responseOutputItemAddedEvent(let event):
//                currentResponse?.output.append(event.item)
//            case .responseContentPartAddedEvent(let event):
//                if var responseItem = currentResponse?.output[event.output_index] {
//                    if case .output_message(var message) = responseItem {
//                        message.content.append(event.part)
//                        currentResponse?.output[event.output_index] = .output_message(message)
//                    }
//                }
//            case .responseOutputTextDeltaEvent(let event):
//                guard var response = currentResponse, response.output.indices.contains(event.output_index) else { break }
//                
//                var responseItem = response.output[event.output_index]
//                if case .output_message(var message) = responseItem {
//                    print("debug message.content: \(message.content)")
//                    print("debug message.content.indices: \(message.content.indices)")
//                    print("debug event.content_index: \(event.content_index)")
//                    if message.content.indices.contains(event.content_index) {
//                        var content = message.content[event.content_index]
//                        if case .output_text(var outputText) = content {
//                            outputText.text += event.delta
//                            content = .output_text(outputText)
//                            message.content[event.content_index] = content
//                            responseItem = .output_message(message)
//                            response.output[event.output_index] = responseItem
//                            currentResponse = response
//                        }
//                    }
//                }
            case .responseCompletedEvent(let event):
                responses.append(event.response)
                
                if case .output_message(let _) = event.response.output.first {
                    if showMinimizedChat {
                        print("Setting Minimized Chat response: \(event.response)")
                        minimizedChatResponse = event.response
                        showChat = false
                    }
                }
//                if showMinimizedChat {
//                    print("Setting Minimized Chat response: \(event.response)")
//                    minimizedChatResponse = event.response
//                }
            default:
                print("UNHANDLED responseStreamEvent: \(streamEvent)")
            }
        }
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

