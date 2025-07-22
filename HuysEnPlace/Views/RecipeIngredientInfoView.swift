//
//  RecipeIngredientInfo.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/20/25.
//

import SwiftUI

struct RecipeIngredientInfo: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var overview: AttributedString
    var roleTitle: String
    var roleDetails: AttributedString
    var ingredient: Ingredient
}

struct RecipeIngredientInfoView: View {
    var info: RecipeIngredientInfo
    
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
                Text(info.name)
                    .font(.title)
                    .bold()
                Text("Overview")
                    .font(.headline)
                Text(info.overview)
                    .font(.body)
                Text(info.roleTitle)
                    .font(.headline)
                Text(info.roleDetails)
                    .font(.body)
                Divider()
                HStack {
                    Text("Link:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(info.ingredient.name)
                        .font(.subheadline)
                }
            }
            .padding()
        }
    }
}

#Preview {
    RecipeIngredientInfoView(info: .init(
        name: "Bread Flour",
        overview: AttributedString("A finely milled flour used for making bread, high in protein content for optimal gluten development."),
        roleTitle: "The role of bread flour in banh mi bread.",
        roleDetails: AttributedString("Gives structure and chew to the finished loaf. Its protein forms gluten when hydrated and kneaded, trapping air bubbles for a light texture."),
        ingredient: Ingredient(id: "bread-flour", name: "Bread Flour")
    ))
}
