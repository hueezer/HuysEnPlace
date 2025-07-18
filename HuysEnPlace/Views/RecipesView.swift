//
//  RecipesView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/18/25.
//

import SwiftUI

struct RecipesView: View {
    @Environment(AppState.self) var appState
    var body: some View {
        @Bindable var appState = appState
        NavigationStack(path: $appState.path) {
            List {
                NavigationLink(value: banhMiRecipe, label: {
                    Text("Banh Mi Recipe")
                })
                
                ForEach(sampleRecipes) { recipe in
                    NavigationLink(value: recipe, label: {
                        Text(recipe.title)
                    })
                }
            }
            .navigationDestination(for: Recipe.self, destination: { recipe in
                RecipeView(recipe: recipe)
            })
        }
    }
}

#Preview {
    RecipesView()
        .environment(AppState())
}
