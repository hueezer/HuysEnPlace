//
//  RecipeIngredientInfo.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/20/25.
//

import SwiftUI
import FoundationModels

struct RecipeIngredientInfo: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var overview: String
    var roleTitle: String
    var roleDetails: String
    var ingredient: Ingredient
}

@Generable
struct GeneratedRecipeIngredientInfo: Codable {
    @Guide(description: "The name of the ingredient")
    var name: String
    
    @Guide(description: "A short overview of the ingredient")
    var overview: String
    
    @Guide(description: "A role title for the ingredient for current recipe")
    var roleTitle: String
    
    @Guide(description: "Details on what role or function the ingredient has within the recipe")
    var roleDetails: String
    
    @Guide(description: "A full description of the ingredient that goes more in depth")
    var fullDescription: String
}

struct RecipeIngredientInfoView: View {
    var recipe: Recipe
    var ingredientQuantity: IngredientQuantity
//    var info: RecipeIngredientInfo
    
    @State private var infoState = RecipeIngredientInfo(name: "", overview: "", roleTitle: "", roleDetails: "", ingredient: Ingredient())
    @State private var description: String = ""
    
    var body: some View {
        ScrollView {
            AsyncImage(url: URL(string: "https://picsum.photos/200")) { image in
                image.resizable()
                    .aspectRatio(1, contentMode: .fit)
            } placeholder: {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(.gray.opacity(0.5))
                .aspectRatio(1, contentMode: .fit)
            }
            VStack(alignment: .leading, spacing: 16) {
                Text(infoState.name)
                    .font(.title)
                    .bold()
                Text("Overview")
                    .font(.headline)
                Text(infoState.overview)
                    .font(.body)
                Text(infoState.roleTitle)
                    .font(.headline)
                Text(infoState.roleDetails)
                    .font(.body)
                Text("Description")
                    .font(.headline)
                Text(description)
                    .font(.body)
                Divider()
                HStack {
                    Text("Link:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(infoState.ingredient.name)
                        .font(.subheadline)
                }
            }
            .padding()
        }
        .task {
            let prompt = """
                Ingredient name: \(ingredientQuantity.ingredientText)
                Recipe name: \(recipe.title)
                """
            
//            if let response = try? await OpenAI.respond(to: prompt, generating: GeneratedRecipeIngredientInfo.self) {
//                infoState.name = response.name
//                infoState.overview = response.overview
//                infoState.roleTitle = response.roleTitle
//                infoState.roleDetails = response.roleDetails
//                description = response.fullDescription
//            }
            
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
            if let response = try? await session.respondTest(to: prompt, generating: GeneratedRecipeIngredientInfo.self) {
                infoState.name = response.name
                infoState.overview = response.overview
                infoState.roleTitle = response.roleTitle
                infoState.roleDetails = response.roleDetails
                description = response.fullDescription
            }
        }
    }
}

#Preview {
    
    RecipeIngredientInfoView(recipe: .init(title: "Banh Mi"), ingredientQuantity: .init(ingredientText: "Bread Flour"))
}
