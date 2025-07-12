//
//  RecipeView2.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/8/25.
//

import SwiftUI

struct RecipeView2: View {
    @State var editMode: EditMode = .inactive
    @Environment(\.fontResolutionContext) var fontResolutionContext
    @State var recipe = banhMiRecipe
    @State var selection = AttributedTextSelection()
    @State var showIngredients: Bool = false
    @State var ingredientInfo: Ingredient?
    
    @Environment(\.self) private var environment
    
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
                    .contentMargins(.horizontal, 12.0, for: .scrollContent)
                    .textEditorStyle(.plain)
            } else {
                ScrollView {
                    let g = AttributedTextFormatting.Transferable(text: recipe.content, in: environment)
                    if let s = try? AttributedString(transferable: g, in: environment) {
                        Text(s)
                        //                        .safeAreaPadding()
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                    }
                }
                .contentMargins(.horizontal, 12.0, for: .scrollContent)
            }
        }
        .navigationTitle(recipe.title)
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
                recipe.ingredients.append(newIngredient)
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
        .sheet(item: $ingredientInfo) { ingredient in
            VStack {
                Text(ingredient.name)
            }
            .presentationDetents([.medium, .large])
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                
                Button("Autotag", systemImage: "wand.and.sparkles.inverse") {
                    let nameString = "Bake"
                    let ranges = RangeSet(self.recipe.content.characters.ranges(of: Array(nameString)))
                    let newIngredient = Ingredient(id: "new-\(nameString)", name: .init(nameString))
                    recipe.ingredients.append(newIngredient)
                    recipe.content.transform(updating: &self.selection) { text in
//                        text[ranges].ingredient = "new-\(nameString)"
//                        text[ranges].link = .init(string: "miseenplace://ingredients/\(newIngredient.id)")
                        text[ranges].foregroundColor = .red
                        
                    }
                }

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
                
//                if !selectionIsEmpty() {
//                    Button("Ingredient", systemImage: "carrot") {
//                        showIngredients.toggle()
//                    }
//                }
                Button("Ingredient", systemImage: "carrot") {
                    showIngredients.toggle()
                }
                
                EditButton()
            }
            
            
            ToolbarItemGroup(placement: .topBarLeading) {
//                RecipeShareLink(recipe: recipe)
                
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
//        .task {
//            do {
//                let r = try Recipe2.fromJsonFile(name: "recipe31")
//                recipe.title = r.title
//                recipe.content = r.content
//                recipe.ingredients = r.ingredients
//            } catch {
//                print("Error loading recipe.")
//            }
//        }
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
                print("recipe ingredients: \(recipe.ingredients)")
                print("path components last: \(url.pathComponents.last)")
                if let pathId = url.pathComponents.last, let ingredient = recipe.ingredients.first(where: { $0.id == pathId }) {
                    ingredientInfo = ingredient
                } else {
                    print("DID NOT FIND INGREDIENT")
                }
            }
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
