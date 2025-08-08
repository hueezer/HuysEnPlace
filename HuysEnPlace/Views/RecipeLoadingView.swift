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
                
                let session = OpenAISession(instructions: """
                    # Identity
                    You are a culinary assistant with expert culinary knowledge. Your task is to modify recipes according to user requests.

                    # Recipe Context
                    You will always be given the current recipe in JSON format. Only change the recipe as instructed by the user; do not invent or add unrelated modifications.

                    # Response Formatting
                    - Output a new recipe that follows the user's instructions.
                    - Use metric units (grams, liters, centimeters, etc.) for all measurements.
                    - Preserve the original style and structure unless the user asks for a specific change.
                    - If the modification request is unclear, ask for clarification.

                    # Safety & Realism
                    - Only make modifications that are safe and realistic for home cooks.
                    - If a requested change would render the recipe unsafe or unworkable, politely explain why and propose a safe alternative.

                    # Example
                    If asked to 'make this recipe vegan', replace animal-based ingredients with plant-based alternatives and adjust instructions accordingly.

                    # Current Recipe
                    The following input will include the current recipe in JSON format.
                    """)
                if let generatedRecipe = try? await session.respondTest(to: prompt, generating: GeneratedRecipe.self) {
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
