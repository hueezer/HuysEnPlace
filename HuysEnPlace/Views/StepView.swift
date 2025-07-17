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
    @State private var showPopover: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
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
        .environment(\.openURL, OpenURLAction { url in
            print("openURL: \(url)")
            if url.scheme == "miseenplace" {
                print("SCHEME: ", url.scheme)
                print("COMPONENTS: ", url.pathComponents)
                
                print("PATH: ", url.path())
//                handleURL(url) // Define this method to take appropriate action.
                showPopover = true
                return .handled
            }
            return .systemAction
        })
        .popover(isPresented: $showPopover) {
            Text("POPOVER")
        }
    }
}

struct StepEditor: View {
    @Binding var text: AttributedString
    @State private var selection = AttributedTextSelection()
    @FocusState private var focused: Bool
    @State private var currentText: AttributedString?
    
    @State private var showDebug: Bool = false
    
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
                    
                    Button(action: {
                        addTimer()
                    }, label: {
                        Image(systemName: "clock")
                            .frame(width: 36, height: 36)
                    })
                    
                    Toggle("Debug", systemImage: "curlybraces", isOn: $showDebug)
                        .toggleStyle(.button)
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
            
            if showDebug {
                if let debugString = getDebugString(text) {
                    Text("DEBUG")
                        .font(.headline)
                        .fontWeight(.light)
                    ScrollView {
                        VStack(spacing: 8) {

                            Text(debugString)
                                .lineLimit(nil)
                                .textSelection(.enabled)
                            Spacer()
                        }
                        .padding()
                    }
                    .font(.body.monospaced())
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .foregroundStyle(Color.primary)
        .padding()
        .attributedTextFormattingDefinition(
            RecipeFormattingDefinition(ingredients: [])
        )
//        .environment(\.openURL, OpenURLAction { url in
//            print("openURL: \(url)")
//            if url.scheme == "miseenplace" {
//                print("SCHEME: ", url.scheme)
//                print("COMPONENTS: ", url.pathComponents)
//                
//                print("PATH: ", url.path())
////                handleURL(url) // Define this method to take appropriate action.
//                showPopover = true
//                return .handled
//            }
//            return .systemAction
//        })

    }
    
    func getDebugString(_ text: AttributedString) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(text) else { return nil }
        return String(data: data, encoding: .utf8)
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
//            text[ranges].foregroundColor = .red
        }
    }
    
    func addTimer() {
        text.transformAttributes(in: &selection) { container in
            container.foregroundColor = .purple
        }
    }
}


#Preview {
    @Previewable @State var step: AttributedString = AttributedString("Place the baguette pans with the dough into the oven. Immediately pour boiling water onto lava rocks and secondary tray. Bake for 8 minutes without opening the door. Open the door to release any leftover steam, and bake 7-8 minutes depending on desired color. Remove the Bánh Mì from the oven and let cool.  Cracks should form after 5-10 minutes.")
    StepView(text: $step)
        .environment(\.editMode, .constant(.active))
        .environment(Recipe2(
            ingredients: [
                .init(title: "Bread", items: [
                    .init(amount: "", ingredientText: "", ingredient: .init(id: "dough", name: "Dough"))
                ])
            ]
        ))
}
