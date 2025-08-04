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
    @State private var chatMessage: String = ""
    
//    @State private var showRecipeDiff: Bool = false
//    @State private var updatedRecipeMessage: String?
    @State private var modifiedRecipe: Recipe?
    @State private var modifyRecipeResponse: GeneratedRecipeResponse?
    @State private var updateRecipeIsGenerating: Bool = false
    
    @Namespace private var namespace

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
                                
                                ForEach(recipe.steps.enumerated(), id: \.offset) { index, step in
                                    StepView(index: index, step: $recipe.steps[index])
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
                                    TextField("How would you change this recipe?", text: $chatMessage, axis: .vertical)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1...10)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .disabled(updateRecipeIsGenerating)
                                    
                                    Button(action: {
                                        Task {
//                                            showRecipeDiff = true
                                            updateRecipeIsGenerating = true
                                            let fullPrompt = """
                                            Modify the following recipe acording to these intructions:
                                            \(chatMessage)
                                            Recipe:
                                            \(recipe.toJson())
                                            """
                                            print("Full Prompt: \(fullPrompt)")
                                            if let response = try? await OpenAI.respond(to: fullPrompt, generating: GeneratedRecipeResponse.self) {
                                                withAnimation {
                                                    modifiedRecipe = Recipe(from: response.recipe)
                                                    modifyRecipeResponse = response
                                                }
                                            }
                                            chatMessage = ""
                                            
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
                    showModifyChat.toggle()
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

