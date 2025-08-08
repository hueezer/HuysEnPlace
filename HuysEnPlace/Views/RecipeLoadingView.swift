//
//  RecipeLoadingView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/27/25.
//

import SwiftUI

struct RecipeLoadingView: View {
    
    var prompt: String?
    var inputRecipe: Recipe?
    
    @State var recipe: Recipe?
    var body: some View {
        VStack {
            if let recipe = recipe {
                RecipeView(recipe: recipe)
            } else {
                VStack(alignment: .center, spacing: 16) {
                    Text("Recipe Title")
                        .font(.title)
                        .bold()
                    Text("Ingredients")
                        .font(.headline)
                    ProgressView()
                }
            }
        }
        .task {
            if let inputRecipe, let prompt {

            } else if let prompt {
//                if let generatedRecipe = try? await OpenAI.respond(to: prompt, generating: GeneratedRecipe.self) {
//                    recipe = Recipe(title: generatedRecipe.title, ingredients: generatedRecipe.ingredients, steps: generatedRecipe.steps.map { Step(text: $0.text, timers: $0.timers) })
//                    
//                    print("GENERATED RECIPE: \(recipe?.steps)")
//                }

                if let generatedRecipe = try? await OpenAISession(instructions: sharedInstructions).respondTest(to: prompt, generating: GeneratedRecipe.self) {
                    recipe = Recipe(title: generatedRecipe.title, ingredients: generatedRecipe.ingredients, steps: generatedRecipe.steps.map { Step(text: $0.text, timers: $0.timers) })
                }
            } else if let inputRecipe {
                recipe = inputRecipe
            } else {
                recipe = banhMiRecipe
            }
        }
    }
}

#Preview {
    RecipeLoadingView(prompt: "Carrot Cake")
}
