//
//  RecipeEditor.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/3/25.
//
//
//import SwiftUI
//
//struct RecipeEditor: View {
//    @Bindable var content: EditableRecipeText
//
//    var body: some View {
//        TextEditor(text: $content.text, selection: $content.selection)
//            .toolbar {
//                ToolbarItemGroup(placement: .topBarTrailing) {
//                    Picker("Paragraph Format", selection: $content.paragraphFormat) {
//                        Text("Section")
//                            .tag(ParagraphFormat.section)
//                        Text("Body")
//                            .tag(ParagraphFormat.body)
//                    }
//                    .pickerStyle(.inline)
//                    .fixedSize()
//                }
//            }
//
//    }
//}
//
//extension EditableRecipeText {
//    /// The paragraph format the current selection exhibits.
//    fileprivate var paragraphFormat: ParagraphFormat {
//        get {
//            let containers = selection.attributes(in: text)
//            let formats = containers[\.paragraphFormat]
//
//            return formats.contains(.section) ? .section : .body
//        }
//        set {
//            text.transformAttributes(in: &selection) {
//                $0.paragraphFormat = newValue
//            }
//        }
//    }
//}
//
//
//
//
//#Preview {
//    @Previewable @State var recipe = banhMiRecipe
//    NavigationStack {
//        RecipeEditor(content: .init(recipe: recipe))
//    }
//}
