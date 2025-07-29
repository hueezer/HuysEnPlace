//
//  AppState.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/18/25.
//

import SwiftUI

@Observable
@MainActor
class AppState {
    var path = NavigationPath()
    var recipeItems: [RecipeItem] = sampleRecipeItems
}
