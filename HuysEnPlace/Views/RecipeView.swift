//
//  RecipeView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/4/25.
//

import SwiftUI

struct RecipeView: View {
    @State var model: Recipe

    @State private var content: EditableRecipeText
    @State private var showIngredientsInspector = false
    @State private var showSettingsSheet = false
    
    @State private var shareJsonUrl: URL?
    @State private var showShareJsonSheet: Bool = false

    init(recipe: Recipe) {
        self.model = recipe
        self._content = State(initialValue: EditableRecipeText(recipe: recipe))
    }

    var body: some View {
        VStack {
//            BackgroundView(imageData: model.image)
            if let url = shareJsonUrl {
                VStack {
                    ShareLink("Share URL", item: url)
                }
            }
            
            RecipeEditor(content: content)
                .scrollContentBackground(.hidden)
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .navigationTitle(model.title)
//                .navigationBarTitleDisplayMode(.large)
            

        }
        .sheet(isPresented: $showIngredientsInspector) {
            InspectorView(
                recipe: model,
                ingredientNameSuggestion: content.ingredientNameSuggestion,
                ingredientSelectionSuggestion: content.ingredientSelectionSuggestion
            )
        }
        .sheet(isPresented: $showSettingsSheet) {
            RecipeSettings(recipe: model)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Toggle("Show Ingredients", systemImage: "basket", isOn: $showIngredientsInspector)
                    .tint(.green)

            }

            ToolbarItemGroup(placement: .topBarLeading) {
//                RecipeShareLink(recipe: model)

                Toggle("Show Recipe Settings", systemImage: "ellipsis.circle", isOn: $showSettingsSheet)
                Button("Share") {
                    if let json = model.toJson() {
                        let url = FileManager.default.temporaryDirectory
                                       .appendingPathComponent("Recipe.json")
                        try? json.write(to: url, atomically: true, encoding: .utf8)
                        shareJsonUrl = url
                    }
                }
            }
        }
        .toolbarRole(.editor)
        .onChange(of: model) {
            content = EditableRecipeText(recipe: model)
        }
        .attributedTextFormattingDefinition(
            RecipeFormattingDefinition(ingredients: Set(model.ingredients.map(\.id)))
        )
        .sheet(isPresented: $showShareJsonSheet, content: {
            VStack {
                let _ = print("shareJsonUrl2: \(shareJsonUrl)")
                Text("Share JSON")
                if let shareJsonUrl {
                    ShareLink("Share URL", item: shareJsonUrl)
                } else {
                    Text("Not Available Yet: \(shareJsonUrl)")
                }
            }
            
        })
    }
}

extension EditableRecipeText {
    fileprivate var ingredientSelectionSuggestion: Set<Ingredient.ID> {
        let selectedAttributes = selection.attributes(in: text)
        let ingredientIdentifiers = selectedAttributes[\.ingredient].compactMap(\.self)

        return Set(ingredientIdentifiers)
    }

    fileprivate var ingredientNameSuggestion: IngredientSuggestion {
        let name = text[selection]

        return IngredientSuggestion(
            suggestedName: AttributedString(name),
            onApply: { ingredientId in
                let ranges = RangeSet(self.text.characters.ranges(of: name.characters))

                self.text.transform(updating: &self.selection) { text in
                    text[ranges].ingredient = ingredientId
                }
            })
    }
}


#Preview {
    @Previewable @State var recipe = banhMiRecipe
    NavigationStack {
        RecipeView(recipe: recipe)
    }
}
