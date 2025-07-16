//
//  StepView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/16/25.
//

import SwiftUI

struct StepView: View {

    @Environment(\.editMode) private var editMode
    var index: Int = 0
    @Binding var text: AttributedString
    @State private var showEditor = false

    var body: some View {
        VStack {
            Text("\(index + 1). ").bold().foregroundStyle(.indigo) + Text(text)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showEditor, content: {
            StepEditor(text: $text)
        })
        .onTapGesture {
            if editMode?.wrappedValue == .active {
                showEditor = true
            }
        }
    }
}

struct StepEditor: View {
    @Binding var text: AttributedString
    @State private var selection = AttributedTextSelection()
    @FocusState private var focused: Bool
    @State private var currentText: AttributedString?
    @Environment(\.dismiss) private var dismiss
    @Environment(Recipe2.self) private var recipe
    
    var body: some View {
        @Bindable var recipe = recipe
        VStack {
            HStack {
                HStack {

                    Button(action: {
                        autotag(recipe: recipe)
//                        autotag(ingredient: .init(id: "dough", name: "Dough"))
//                        
//                        autotag(ingredient: .init(id: "water", name: "water"))
                    }, label: {
                        Image(systemName: "carrot")
                            .frame(width: 36, height: 36)
                    })
                    
                    Button(action: {}, label: {
                        Image(systemName: "clock")
                            .frame(width: 36, height: 36)
                    })
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                
                .glassEffect(in: Capsule())
                
                Spacer()
                
                Button(action: {
                    if let currentText = currentText {
                        text = currentText
                    }
                }, label: {
                    Image(systemName: "arrow.uturn.backward")
                        .frame(width: 36, height: 36)
                })
                .buttonBorderShape(.circle)
                .buttonStyle(.glass)
                .disabled(text == currentText)
                
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "checkmark")
                        .frame(width: 36, height: 36)
                })
                .buttonBorderShape(.circle)
                .buttonStyle(.glassProminent)
            }
            .font(.system(size: 24, weight: .light, design: .default))
            .labelStyle(.iconOnly)

            TextEditor(text: $text, selection: $selection)
                .focused($focused)
                .textEditorStyle(.plain)
                .scrollContentBackground(.hidden)
                .onAppear {
                    focused = true
                    currentText = text
                }
        }
        .foregroundStyle(Color.primary)
        .padding()
        .attributedTextFormattingDefinition(
            RecipeFormattingDefinition(ingredients: [])
        )
    }
    
    func autotag(ingredients: [Ingredient]) {
        for ingredient in ingredients {
            autotag(ingredient: ingredient)
        }
    }
    
    func autotag(recipe: Recipe2) {
        for list in recipe.ingredients {
            for item in list.items {
                if let ingredient = item.ingredient {
                    autotag(ingredient: ingredient)
                }
                
            }
        }
    }
    
    func autotag(ingredient: Ingredient) {
        
        print("Attempting to autotag: \(ingredient.name)")
        let nameString = ingredient.name
        var ranges = RangeSet(self.text.characters.ranges(of: Array(nameString)))
        
        let lowercaseRanges = RangeSet(self.text.characters.ranges(of: Array(nameString.lowercased())))
        
        ranges.formUnion(lowercaseRanges)
        
        text.transform(updating: &self.selection) { text in
            text[ranges].ingredient = ingredient.id
            text[ranges].link = .init(string: "miseenplace://ingredients/\(ingredient.id)")
            text[ranges].foregroundColor = .red
        }
    }
}


#Preview {
    StepView(text: .constant("Place the baguette pans with the dough into the oven. Immediately pour boiling water onto lava rocks and secondary tray. Bake for 8 minutes without opening the door. Open the door to release any leftover steam, and bake 7-8 minutes depending on desired color. Remove the Bánh Mì from the oven and let cool.  Cracks should form after 5-10 minutes."))
        .environment(\.editMode, .constant(.active))
        .environment(Recipe2(
            ingredients: [
                .init(title: "Bread", items: [
                    .init(amount: "", ingredientText: "", ingredient: .init(id: "dough", name: "Dough"))
                ])
            ]
        ))
}
