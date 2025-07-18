//
//  RecipeShareLink.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/10/25.
//

import SwiftUI

struct RecipeShareLink: View {
    let recipe: Recipe
    @Environment(\.self) private var environment

    var body: some View {
        let _ = print("CONTENT: \(recipe.content)")
        ShareLink(
            item: AttributedTextFormatting.Transferable(text: recipe.content, in: environment),
            subject: Text("Try my recipe for \(recipe.title)"),
            preview: SharePreview("\(recipe.title)"))
    }
}
