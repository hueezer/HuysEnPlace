//
//  ContentView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/3/25.
//

import SwiftUI

struct ContentView: View {
    @State var recipe = banhMiRecipe
    var body: some View {
        NavigationStack {
//            RecipeView(recipe: recipe)
            RecipeView()
        }
    }
}

#Preview {
    ContentView()
}
