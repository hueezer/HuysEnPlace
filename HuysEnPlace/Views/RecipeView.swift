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
    
    @Namespace private var namespace
    
    @State private var previousResponseid: String? = nil

    var body: some View {
        @Bindable var recipe = recipe
        VStack {
            if let url = shareJsonUrl {
                VStack {
                    ShareLink("Share URL", item: url)
                }
            }
            
//            let runs = Array(recipe.content.runs)
//
//            runs.reduce(Text("")) { partialResult, run in
//                let range = run.range
//                let substring = recipe.content[range]
//
//                let textView = Text(AttributedString(substring))
//
//                if run.attributes.ingredient != nil {
//                    return partialResult + textView + Text(" ") +  Text("New")
//                        .bold()
//                        .foregroundStyle(.red)
//                }
//                return partialResult + textView
//            }
//            
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
                                
//                                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
//                                    StepView(index: index, step: $recipe.steps[index])
//                                        .environment(recipe)
//                                        .shadow(color: editMode == .active ? .blue : .clear, radius: 0)
//                                }
                                
                                ForEach(Array(zip(recipe.steps.indices, $recipe.steps)), id: \.1.id) { index, $step in
                                    StepView(index: index, step: $step)
                                        .environment(recipe)
                                        .shadow(color: editMode == .active ? .blue : .clear, radius: 0)
                                }
                                
//                                ForEach($recipe.steps) { $step in
//                                    StepView(index: 1, step: $step)
//                                        .environment(recipe)
//                                        .shadow(color: editMode == .active ? .blue : .clear, radius: 0)
//                                }
                                
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
            //                                .glassEffect(.regular.tint(.blue).interactive(), in: RoundedRectangle(cornerRadius: 16))
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
//                                                        modifyRecipeResponse = .init(message: "I modified the recipe", recipe: generatedRecipe)
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
        .attributedTextFormattingDefinition(
            RecipeFormattingDefinition(ingredients: Set(ingredients.map(\.id)))
        )
        .onAppear {
            recipe.content = banhMiRecipeContent
        }
        .sheet(isPresented: $showChat) {
            
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
                    let testRecipe = Recipe(title: "TEST", steps: [
                        Step(text: "Prepare the levain: In a small jar, mix **50 g** of [Bread Flour](miseenplace://ingredients/bread-flour), **50 g** of [Water](miseenplace://ingredients/water) and **10 g** of mature [Sourdough Starter](miseenplace://ingredients/sourdough-starter) (100% hydration). Cover loosely and ferment at **26 °C** for **8–12 h** until doubled, domed and bubbly."),
                        Step(text: "Mix the final dough: In the bowl of a stand mixer, combine **210 g** of [Water](miseenplace://ingredients/water), **50 g** of beaten [Whole Egg](miseenplace://ingredients/egg), all the ripe levain (about **110 g**), **2 g** of [Sugar](miseenplace://ingredients/sugar), **2 g** of [Salt](miseenplace://ingredients/salt) and **1 g** of [Ascorbic Acid](miseenplace://ingredients/ascorbic-acid) (optional). Add **400 g** of [Bread Flour](miseenplace://ingredients/bread-flour) and mix with a dough hook on low for **5 min**, then medium-high for **3 min** until smooth with a thin windowpane."),
                        Step(text: "Lightly oil the work surface with [Vegetable Oil](miseenplace://ingredients/vegetable-oil). Transfer the dough, give **4–6** gentle slap-and-folds, shape into a ball, cover and rest **30 min** (fermentolyse)."),
                        Step(text: "Bulk-ferment for **4–5 h** at **26 °C**, giving the dough two to three letter-folds every **60 min**. Aim for a **70–80%** rise and a light, airy feel."),
                        Step(text: "Optional flavor build: After the first **60–90 min** of bulk, you may cover and refrigerate the dough for **8–12 h** at **4 °C**. Next day, let it warm at room temp until puffy before proceeding."),
                        Step(text: "Divide into six **120 g** pieces. Pre-shape into loose balls, cover and bench-rest **20 min**."),
                        Step(text: "Shape each piece into a tight torpedo (see baguette-shaping references). Place seam-side-down on a lightly oiled baguette pan."),
                        Step(text: "Final proof at **26 °C** (oven with light on and a pan of warm water) for **3–3½ h**, misting the loaves lightly with water every **15 min**. They should expand **2.5–3×** and feel very light."),
                        Step(text: "Preheat the oven to **230 °C** (Bake, bottom heat or no fan) with two trays, one filled with lava rocks for steam."),
                        Step(text: "Bring a kettle of water to a boil. When loaves are ready, score with a lame, mist the surfaces, slide pans into the oven and carefully pour the boiling water over the lava rocks."),
//                        Step(text: "Bake **10 min** without opening the door, then vent the steam and bake a further **7–9 min** until deep golden and very light in weight."),
//                        Step(text: "Remove the Bánh Mì and cool on a rack. Cracks should begin to sing and appear after **5–10 min**; serve warm for the classic crisp-thin crust.")
                    ])
//                    modifiedRecipe = testRecipe
                    modifiedRecipe = Recipe()
                    modifiedRecipe?.title = testRecipe.title
                    modifiedRecipe?.ingredients = testRecipe.ingredients
                    modifiedRecipe?.steps = testRecipe.steps
                }

                
                if editMode.isEditing {
                    Button("Save", systemImage: "checkmark") {
                        withAnimation {
                            editMode = .inactive
                        }
                    }
                    .buttonStyle(.glassProminent)
                }

//                Button("Bold", systemImage: "bold") {
//                    recipe.content.transformAttributes(in: &selection) { container in
//                        let currentFont = container.font ?? .default
//                        let resolved = currentFont.resolve(in: fontResolutionContext)
//                        container.font = currentFont.bold(!resolved.isBold)
//                    }
//                }
//
//                Button("Italic", systemImage: "italic") {
//                    recipe.content.transformAttributes(in: &selection) { container in
//                        let currentFont = container.font ?? .default
//                        let resolved = currentFont.resolve(in: fontResolutionContext)
//                        container.font = currentFont.italic(!resolved.isItalic)
//                    }
//                }
                
//                if !selectionIsEmpty() {
//                    Button("Ingredient", systemImage: "carrot") {
//                        showIngredients.toggle()
//                    }
//                }

                
//                Button("Ingredient", systemImage: editMode.isEditing ? "checkmark" : "pencil") {
//                    withAnimation {
//                        if editMode.isEditing {
//                            editMode = .inactive
//                        } else {
//                            editMode = .active
//                        }
//                    }
//                }
//                .buttonStyle(.glassProminent)
//                .tint(editMode.isEditing ? .green : .blue)
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
                Button(action: {
                    showChat.toggle()
                }, label: {
                    Label("Chat", systemImage: "message")
                })
                .buttonStyle(.glassProminent)
            }
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

