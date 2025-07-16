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
    @FocusState private var focused: Bool
    @State private var currentText: AttributedString?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    if let currentText = currentText {
                        text = currentText
                    }
                    currentText = nil
                    dismiss()
                }, label: {
                    Label("Cancel", systemImage: "xmark")
                })
                .buttonStyle(.glass)
                .tint(.red)
                
                Button(action: {
                    dismiss()
                }, label: {
                    Label("Done", systemImage: "checkmark")
                })
                .buttonStyle(.glassProminent)
            }

            TextEditor(text: $text)
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
    }
}


#Preview {
    StepView(text: .constant("Hello, World!"))
}
