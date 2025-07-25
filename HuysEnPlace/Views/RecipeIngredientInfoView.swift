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
            
            if let response = try? await OpenAI.respond(to: prompt, generating: GeneratedRecipeIngredientInfo.self) {
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
