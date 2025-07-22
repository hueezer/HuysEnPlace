//
//  RecipesView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/18/25.
//

import SwiftUI

struct RecipesView: View {
    @Environment(AppState.self) var appState
    @Namespace private var namespace
    var body: some View {
        @Bindable var appState = appState
        NavigationStack(path: $appState.path) {
            ScrollView {
                let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink(value: banhMiRecipe, label: {
                        VStack {
                            AsyncImage(url: URL(string: "https://picsum.photos/200")) { phase in
                                phase.image?.resizable()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .clipped()
                                    .aspectRatio(1, contentMode: .fit)
                            }
                            
                            
                            Text(banhMiRecipe.title)
                                .padding(.bottom, 8)
                            Spacer()
                        }
//                        .frame(maxWidth: .infinity, minHeight: 60)
                        .matchedTransitionSource(id: "world", in: namespace)
                        
                    })

                    ForEach(sampleRecipes) { recipe in
                        NavigationLink(value: recipe, label: {
                            VStack {
                                AsyncImage(url: URL(string: "https://picsum.photos/200")) { image in
                                    image.resizable()
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .clipped()
                                } placeholder: {
                                    VStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background(.gray.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .clipped()
                                    .aspectRatio(1, contentMode: .fit)
                                }
                                
                                Text(recipe.title)
                                    .padding(.bottom, 8)
                                Spacer()
                            }
                            .foregroundStyle(.primary)
//                            .frame(maxWidth: .infinity, minHeight: 60)
                            .matchedTransitionSource(id: "world", in: namespace)
                        })
                    }
                }
                .padding()
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self, destination: { recipe in
                RecipeView(recipe: recipe)
                    .navigationTransition(.zoom(sourceID: "world", in: namespace))
            })
        }
    }
}

#Preview {
    RecipesView()
        .environment(AppState())
}
