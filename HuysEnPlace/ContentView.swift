//
//  ContentView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var app = AppState()
    @State var recipe = banhMiRecipe
    var body: some View {
        TabView {
            Tab("Recipes", systemImage: "text.page") {
                RecipesView()
                    .environment(app)
            }
            .badge(2)


            Tab("Ingredients", systemImage: "carrot") {
                RecipesView()
                    .environment(app)
            }
            
            Tab("Chat", systemImage: "bubble.left.and.bubble.right") {
                ChatContainer()
                    .environment(app)
            }
            .badge("!")


            Tab("Podcasts", systemImage: "carrot") {
                StreamTestView()
                    .environment(app)
            }
            .badge("!")
            
            Tab("Recipe Diff", systemImage: "carrot") {
                ScrollView {
                    RecipeDiffView(recipe: banhMiRecipe, updatedRecipe: .constant(banhMiRecipeDiff))
                        .safeAreaPadding()
                        .padding(.top, 50)
                }
                .environment(app)
            }
            .badge("!")
            

            
            Tab(role: .search) {
                Text("Search")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)

    }
}

#Preview {
    ContentView()
}
