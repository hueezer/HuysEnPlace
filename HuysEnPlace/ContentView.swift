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


            Tab("Podcasts", systemImage: "carrot") {
                StreamTestView()
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
