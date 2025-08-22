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
                InfoView(subjectName: "Ascorbic Acid", context: "In Banh Mi")
                    .environment(app)
            }
            
            Tab("Chat", systemImage: "bubble.left.and.bubble.right") {
                ChatContainer()
                    .environment(app)
            }
            .badge("!")


            Tab("Podcasts", systemImage: "carrot") {
                ResponseInspector()
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
