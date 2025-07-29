//
//  IngredientListEditor.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/14/25.
//

import SwiftUI

struct IngredientListEditor: View {
    
    @Binding var list: IngredientList
    
    var body: some View {
        List {
            Section {
                TextField("Title", text: $list.title)
                    .multilineTextAlignment(.center)
            }
            ForEach($list.items) { $item in
                HStack {
                    TextField("Amount", text: $item.quantity)
                        .fixedSize()
                        .multilineTextAlignment(.trailing)
                    TextField("Ingredient Text", text: $item.ingredientText)
                }
            }
            .onMove(perform: move)
            .onDelete(perform: delete)
            
            Section {
                Button(action: add, label: {
                    Label("Add Ingredient", systemImage: "plus")
                })
            }
        }
        .environment(\.editMode, Binding.constant(EditMode.active))
    }
    
    func move(from source: IndexSet, to destination: Int) {
        list.items.move(fromOffsets: source, toOffset: destination)
    }
    
    func delete(at offsets: IndexSet) {
        list.items.remove(atOffsets: offsets)
    }
    
    func add() {
        list.items.append(.init(quantity: "", ingredientText: ""))
    }
}

#Preview {
    @Previewable @State var ingredientList: IngredientList = .init(title: "For the Bread", items: [
        .init(quantity: "400g", ingredientText: "All-purpose flour"),
        .init(quantity: "1 tsp", ingredientText: "Salt"),
        .init(quantity: "1 tsp", ingredientText: "Active dry yeast"),
        .init(quantity: "100ml", ingredientText: "Warm water"),
        .init(quantity: "100ml", ingredientText: "Vegetable oil"),
    ])
    IngredientListEditor(list: $ingredientList)
}
