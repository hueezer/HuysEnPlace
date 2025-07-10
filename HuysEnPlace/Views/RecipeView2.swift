//
//  RecipeView2.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/8/25.
//

import SwiftUI

//struct RecipeView2: View {
//    
//    @State var recipe: Recipe
//    
//    var body: some View {
////        @Bindable var recipe = recipe
//        VStack {
//            VStack {
//                Text(recipe.title)
//                    .font(.headline)
////                Text(recipe.content)
//                TextEditor(text: $recipe.content)
//            }
//        }
//        .attributedTextFormattingDefinition(
//            RecipeFormattingDefinition(ingredients: Set(recipe.ingredients.map(\.id)))
//        )
//    }
//}

struct RecipeView2: View {
    @State var editMode: EditMode = .inactive
//    @Environment(\.editMode) private var editMode
    @Environment(\.fontResolutionContext) var fontResolutionContext
    @State var recipe = Recipe2()
    @State var selection = AttributedTextSelection()
    @State var showIngredients: Bool = false
    @State var ingredientInfo: Ingredient?
    
    @State private var shareJsonUrl: URL?

    var body: some View {
        @Bindable var recipe = recipe
        VStack {
            if let url = shareJsonUrl {
                VStack {
                    ShareLink("Share URL", item: url)
                }
            }
            if editMode == .active {
                TextEditor(text: $recipe.content, selection: $selection)
                    .contentMargins(.horizontal, 20.0, for: .scrollContent)
                    .textEditorStyle(.plain)
            } else {
                ScrollView {

                    Text(recipe.content)
//                        .safeAreaPadding()
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                .contentMargins(.horizontal, 20.0, for: .scrollContent)
                .onTapGesture(count: 2) {  // or single-tap if you prefer
                    withAnimation {
                        editMode = .active
                    }
                }
            }
        }
        .attributedTextFormattingDefinition(
            RecipeFormattingDefinition(ingredients: Set(recipe.ingredients.map(\.id)))
        )
        .onAppear {
            recipe.content = banhMiRecipeContent
        }
        .sheet(isPresented: $showIngredients) {
            let name = self.recipe.content[selection]
            let nameString = String(name.characters)
            ForEach(recipe.ingredients) { ingredient in
                Button(action: {
                    let ranges = RangeSet(self.recipe.content.characters.ranges(of: name.characters))
                    recipe.content.transform(updating: &self.selection) { text in
                        print("text ranges: \(text[ranges])")
                        print("ingredient id: \(ingredient.id)")
                        text[ranges].ingredient = ingredient.id
//                        text[ranges].link = .init(string: "miseenplace://ingredients/\(ingredient.id)")
                    }
//                    recipe.content.transformAttributes(in: &selection) { container in
//                        container.ingredient = ingredient.id
//                        
//                    }
                    showIngredients = false
                }, label: {
                    Text(ingredient.name)
                })
            }
            
            Button(action: {
                let ranges = RangeSet(self.recipe.content.characters.ranges(of: name.characters))
                let newIngredient = Ingredient(id: "new-\(nameString)", name: .init(nameString))
                recipe.ingredients.append(newIngredient)
                recipe.content.transform(updating: &self.selection) { text in
                    print("text ranges: \(text[ranges])")
//                    print("ingredient id: \(ingredient.id)")
                    text[ranges].ingredient = "new-\(nameString)"
//                        text[ranges].link = .init(string: "miseenplace://ingredients/\(ingredient.id)")
                }
                recipe.content.transformAttributes(in: &selection) { container in
                    container.ingredient = "new-\(nameString)"

                }
                showIngredients = false
            }, label: {
                Text(nameString)
            })
        }
        .sheet(item: $ingredientInfo) { ingredient in
            VStack {
                Text(ingredient.name)
            }
            .presentationDetents([.medium, .large])
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {

                Button("Bold", systemImage: "bold") {
                    recipe.content.transformAttributes(in: &selection) { container in
                        let currentFont = container.font ?? .default
                        let resolved = currentFont.resolve(in: fontResolutionContext)
                        container.font = currentFont.bold(!resolved.isBold)
                    }
                }

                Button("Italic", systemImage: "italic") {
                    recipe.content.transformAttributes(in: &selection) { container in
                        let currentFont = container.font ?? .default
                        let resolved = currentFont.resolve(in: fontResolutionContext)
                        container.font = currentFont.italic(!resolved.isItalic)
                    }
                }
                
                if !selectionIsEmpty() {
                    Button("Ingredient", systemImage: "carrot") {
                        showIngredients.toggle()
                    }
                }
                
                EditButton()
            }
            
            
            ToolbarItemGroup(placement: .topBarLeading) {
                
                Button("Share", systemImage: "square.and.arrow.up") {
                    if let json = recipe.toJson() {
                        let url = FileManager.default.temporaryDirectory
                                       .appendingPathComponent("Recipe.json")
                        try? json.write(to: url, atomically: true, encoding: .utf8)
                        shareJsonUrl = url
                    }
                }
            }
        }
        .task {
//            if let r = try? AttributedString(styledMarkdown: banhMiRecipeMarkdown) {
//                recipe.content = r
//            }
            do {
                let r = try Recipe2.fromJsonFile(name: "recipe3")
                print("LOADED HERE 1 \(r.content)")
                recipe.title = r.title
                recipe.content = r.content
            } catch {
                print("Error loading recipe.")
            }
        }
        .task {
            recipe.ingredients = [
                .init(id: "bread-flour", name: "Bread Flour"),
                .init(id: "water", name: "Water")
            ]
        }
        .environment(\.editMode, $editMode)
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "miseenplace" {
                print("SCHEME: ", url.scheme)
                print("COMPONENTS: ", url.pathComponents)
                
                print("PATH: ", url.path())
                handleURL(url) // Define this method to take appropriate action.
                return .handled
            }
            return .systemAction
        })
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
    
    private func handleURL(_ url: URL) {
        // Any side effect you need—navigation, async task, analytics, …
        print("Link tapped:", url.absoluteString)
        if let host = url.host() {
            if host == "ingredients" {
                print("Tapped Ingredients")
                if let ingredient = recipe.ingredients.first(where: { $0.id == url.pathComponents.last }) {
                    ingredientInfo = ingredient
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var recipe = banhMiRecipe
    NavigationStack {
        RecipeView2()
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
