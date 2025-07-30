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
    
    @State private var showGenerateRecipe = false
    @State private var generatePrompt: String = ""
    @State private var isGenerating = false
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

                    ForEach($appState.recipeItems.reversed()) { $recipeItem in
                        NavigationLink(value: recipeItem, label: {
                            RecipeItemView(recipeItem: $recipeItem)
                                .matchedTransitionSource(id: "world", in: namespace)
                        })
                    }
                }
                .padding()
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self, destination: { recipe in
//                RecipeView(recipe: recipe)
//                    .navigationTransition(.zoom(sourceID: "world", in: namespace))
                RecipeLoadingView(inputRecipe: recipe)
                    .navigationTransition(.zoom(sourceID: "world", in: namespace))
            })
            .navigationDestination(for: RecipeItem.self, destination: { recipeItem in
                if let recipe = recipeItem.recipe {
                    RecipeView(recipe: recipe)
                        .navigationTransition(.zoom(sourceID: "world", in: namespace))
                    //                RecipeLoadingView(inputRecipe: recipe)
                    //                    .navigationTransition(.zoom(sourceID: "world", in: namespace))
                }
            })
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        showGenerateRecipe = true
//                        appState.recipeItems.append(RecipeItem(prompt: "Carrot Cake"))
                    }, label: {
                        Label("Add Recipe", systemImage: "plus")
                    })
                }
            }
            .sheet(isPresented: $showGenerateRecipe, content: {
                VStack {
                    TextField("Recipe name", text: $generatePrompt)
                        
                    Button("Generate", systemImage: "sparkles") {
                        appState.recipeItems.append(RecipeItem(prompt: generatePrompt))
                        generatePrompt = ""
                        showGenerateRecipe = false
                    }
                    .buttonStyle(.glassProminent)
                    .symbolEffect(.bounce, isActive: isGenerating)
                }
                .safeAreaPadding()
                .presentationDetents([.medium])
            })
        }
    }
}

struct RecipeItemView: View {
    @Environment(AppState.self) var appState
    @Binding var recipeItem: RecipeItem
    @State var inProgress: Bool = false
    var body: some View {
        VStack {
            if let imageURL = recipeItem.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
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
            } else {
                VStack {
                    Spacer()
                    if inProgress {
                        ProgressView()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(.blue.gradient.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .clipped()
                .aspectRatio(1, contentMode: .fit)
            }
            Text(recipeItem.title)
                .padding(.bottom, 8)
            Spacer()
        }
        .foregroundStyle(.primary)
        .task {
            if let recipe = recipeItem.recipe, let prompt = recipeItem.prompt {
                inProgress = true
                recipeItem.title = "In Progress"
                let fullPrompt = """
                    Modify the following recipe acording to these intructions:
                    \(prompt)
                    Recipe:
                    \(recipe.toJson())
                    """
                print("Full Prompt: \(fullPrompt)")
                if let generatedRecipe = try? await OpenAI.respond(to: fullPrompt, generating: GeneratedRecipe.self) {
                    recipeItem.title = generatedRecipe.title
                    recipeItem.recipe = Recipe(title: generatedRecipe.title, ingredients: generatedRecipe.ingredients, steps: generatedRecipe.steps.map { Step(text: $0.text) })
                    recipeItem.imageURL = "https://picsum.photos/200"
                    inProgress = false
                }
            } else if let prompt = recipeItem.prompt {
                inProgress = true
                recipeItem.title = "In Progress"
                if let generatedRecipe = try? await OpenAI.respond(to: prompt, generating: GeneratedRecipe.self) {
                    recipeItem.title = generatedRecipe.title
                    recipeItem.recipe = Recipe(title: generatedRecipe.title, ingredients: generatedRecipe.ingredients, steps: generatedRecipe.steps.map { Step(text: $0.text) })
                    recipeItem.imageURL = "https://picsum.photos/200"
                    inProgress = false
                }
            }
        }
        .contextMenu {
            Label("Modify Recipe", systemImage: "arrow.trianglehead.branch")
            if let recipe = recipeItem.recipe {
                Button {
                    appState.recipeItems.append(RecipeItem(prompt: "Make this recipe vegan", recipe: recipe))
                } label: {
                    Label("Make it vegan", systemImage: "heart")
                }
                Button {
                    // Open Maps and center it on this item.
                } label: {
                    Label("Show in Maps", systemImage: "mappin")
                }
            }
        }
    }
}

#Preview {
    RecipesView()
        .environment(AppState())
}
