//
//  RecipeItem.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/27/25.
//

import SwiftUI

struct RecipeItem: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String = ""
    var imageURL: String?
    var prompt: String?
    var recipe: Recipe?
    
    init(title: String = "", imageURL: String? = nil, prompt: String? = nil, recipe: Recipe? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.imageURL = imageURL
        self.prompt = prompt
        self.recipe = recipe
    }
    
    init(from generatedRecipe: GeneratedRecipe) {
        self.title = generatedRecipe.title
        self.recipe = Recipe(title: generatedRecipe.title, ingredients: generatedRecipe.ingredients, steps: generatedRecipe.steps.map { Step(text: $0.text, timers: $0.timers) })
        self.imageURL = "https://picsum.photos/200"
    }
}
