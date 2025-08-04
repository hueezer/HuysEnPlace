//
//  RecipeDiffView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/2/25.
//

import SwiftUI

struct RecipeDiffView: View {
    var recipe: Recipe
    @Binding var updatedRecipe: Recipe?
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
//            if updateRecipeIsGenerating {
//                ProgressView()
//            }
            
            Text("Title")
                .font(.headline)
            
            DiffLoadingView {
                if let updatedRecipe = updatedRecipe {
                    DiffView(old: recipe.title, new: updatedRecipe.title)
                } else {
                    TitleLoadingPlaceholder()
                }
            }
            
            Text("Ingredients")
                .font(.headline)
            
            DiffLoadingView(alignment: .leading) {
                if let updatedRecipe = updatedRecipe {
                    DiffView(old: recipe.ingredientsText(), new: updatedRecipe.ingredientsText(), alignment: .leading)
                } else {
                    IngredientLoadingPlaceholder()
                }
            }
            
            Text("Steps")
                .font(.headline)
            
            DiffLoadingView(alignment: .leading) {
                if let updatedRecipe = updatedRecipe {
                    DiffView(old: recipe.stepsText(), new: updatedRecipe.stepsText(), alignment: .leading)
                } else {
                    VStack(spacing: 16) {
                        StepLoadingPlaceholder()
                        StepLoadingPlaceholder()
                        StepLoadingPlaceholder()
                    }
                }
            }
            
            if updatedRecipe != nil {
                RecipeKey()
            }

        }
    }
}

struct DiffLoadingView<Content: View>: View {
    var alignment: Alignment = .center
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .font(.system(.subheadline, design: .monospaced))
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TitleLoadingPlaceholder: View {
    let ingredients: [[CGFloat]] = [
        [32, 64, 72],
        [40, 80, 120],
        [24, 80, 96],
        [32, 64, 120],
        
    ]
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 120, height: 18)
        }
        .padding(.vertical, 4)
    }
}

struct IngredientLoadingPlaceholder: View {
    let ingredients: [[CGFloat]] = [
        [32, 64, 72],
        [40, 80, 120],
        [24, 80, 96],
        [32, 64, 120],
        
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 96, height: 18)
                .padding(.bottom, 8)
            ForEach(ingredients, id: \.self) { barWidths in
                HStack {
                    ForEach(barWidths, id: \.self) { width in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: width, height: 18)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StepLoadingPlaceholder: View {
    let barWidths: [CGFloat] = [0.95, 0.8, 0.9, 0.6]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(barWidths, id: \.self) { width in
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: UIScreen.main.bounds.width * width * 0.7, height: 18)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecipeKey: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Key")
                .bold()
            Divider()
            
            Text("Additions")
                .foregroundStyle(.green)
            
            Text("Removals")
                .strikethrough()
                .foregroundStyle(.red)
            
            Text("Unchanged")
            
            Text("Links")
                .foregroundStyle(.blue)
        }
        .font(.system(.subheadline, design: .monospaced))
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .fixedSize()
    }
}

#Preview {
    ScrollView {
        RecipeDiffView(recipe: banhMiRecipe, updatedRecipe: .constant(nil))
            .safeAreaPadding()
            .padding(.top, 50)
    }
}
