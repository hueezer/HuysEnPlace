//
//  IngredientListView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/14/25.
//

import SwiftUI

struct IngredientListView: View {
    
    @Environment(\.editMode) private var editMode
    @Binding var list: IngredientList
    
    var onTapIngredient: (IngredientQuantity) -> Void = { _ in }
    var onTapList: (IngredientList) -> Void = { _ in }
    
    var ingredientForegroundColor: Color {
        if editMode?.wrappedValue == .active {
            Color.primary
        } else {
            Color.blue
        }
    }
    
    var foregroundColor: Color {
        if editMode?.wrappedValue == .active {
            Color.primary
        } else {
            Color.primary
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(list.title)
                .bold()
                .padding(.vertical, 8)
            ForEach($list.items) { $item in
                HStack(alignment: .top) {
                    
                    Text(item.quantity)
                        .bold()
                        .fixedSize()
                        .frame(minWidth: 60, alignment: .topTrailing)
                        .multilineTextAlignment(.trailing)
                    
                    Text("\(item.ingredientText)")
                        .foregroundStyle(ingredientForegroundColor) +
                    Text(" \(item.note)")
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .onTapGesture {
                    if editMode?.wrappedValue == .inactive {
                        onTapIngredient(item)
                    } else {
                        onTapList(list)
                    }
                }
            }
        }
        .foregroundStyle(foregroundColor)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(content: {
            Color.clear
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
        })
        .onTapGesture {
            if editMode?.wrappedValue == .active {
                onTapList(list)
            }
        }
    }
}

#Preview {
    @Previewable @State var editMode: EditMode = .inactive
    @Previewable @State var ingredientList: IngredientList = .init(title: "For the Bread", items: [
        .init(quantity: "400g", ingredientText: "All-purpose flour"),
        .init(quantity: "1 tsp", ingredientText: "Salt"),
        .init(quantity: "1 tsp", ingredientText: "Active dry yeast"),
        .init(quantity: "100ml", ingredientText: "Warm water", note: "75°F"),
        .init(quantity: "100ml", ingredientText: "Vegetable oil and a very long ingredient text", note: "as needed"),
    ])
    NavigationStack {
        IngredientListView(list: $ingredientList)
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .principal, content: {
                    Button("edit") {
                        withAnimation {
                            if editMode.isEditing {
                                editMode = .inactive
                            } else {
                                editMode = .active
                            }
                        }
                    }
                })
            }
    }
}
