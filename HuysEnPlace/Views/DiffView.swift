//
//  DiffView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/31/25.
//

import SwiftUI

enum Kind { case equal, deletion, insertion }

struct Fragment: Identifiable {
    let id = UUID()
    let text: String
    let kind: Kind
}

/// Convert the two sides & their diff into a linear stream of `Fragment`s.
func fragments(original: [Substring], revised: [Substring],
               diff: CollectionDifference<Substring>) -> [Fragment] {
    
    // Quick lookup tables
    let removals = Dictionary(uniqueKeysWithValues: diff.removals.compactMap {
        if case let .remove(offset, element, _) = $0 {
            return (offset, element)
        } else {
            return nil
        }
    })
    let insertions = Dictionary(uniqueKeysWithValues: diff.insertions.compactMap {
        if case let .insert(offset, element, _) = $0 {
            return (offset, element)
        } else {
            return nil
        }
    })

    
    var result: [Fragment] = []
    var rIndex = 0, oIndex = 0

    while oIndex < original.count || rIndex < revised.count {
        if let removed = removals[oIndex] {
            result.append(.init(text: String(removed) + " ", kind: .deletion))
            oIndex += 1                                // skip only the old side
        } else if let inserted = insertions[rIndex] {
            result.append(.init(text: String(inserted) + " ", kind: .insertion))
            rIndex += 1                                // skip only the new side
        } else {
            result.append(.init(text: String(revised[rIndex]) + " ", kind: .equal))
            oIndex += 1;  rIndex += 1                  // advance both
        }
    }
    return result
}

struct DiffView: View {
    var old: String
    var new: String
    var alignment: Alignment = .center
    
    func splitRetainingNewlines(_ input: String) -> [Substring] {
        var result: [Substring] = []
        var start = input.startIndex

        var i = start
        while i < input.endIndex {
            if input[i] == "\n" {
                if start < i {
                    result.append(input[start..<i])
                }
                result.append(input[i..<input.index(after: i)]) // The newline itself
                i = input.index(after: i)
                start = i
            } else if input[i].isWhitespace {
                if start < i {
                    result.append(input[start..<i])
                }
                // Skip this whitespace
                i = input.index(after: i)
                start = i
            } else {
                i = input.index(after: i)
            }
        }
        if start < input.endIndex {
            result.append(input[start..<input.endIndex])
        }
        return result
    }
    
    var pieces: [Fragment] {
//        let splitter: (String) -> [Substring] = {
//            $0.split(omittingEmptySubsequences: false, whereSeparator: { $0.isWhitespace })
//        }
        let splitter: (String) -> [Substring] = { splitRetainingNewlines($0) }
        
        let original = splitter(old)
        let revised = splitter(new)
        let diff = revised.difference(from: original)
        // Quick lookup tables
        let removals = Dictionary(uniqueKeysWithValues: diff.removals.compactMap {
            if case let .remove(offset, element, _) = $0 {
                return (offset, element)
            } else {
                return nil
            }
        })
        
        let insertions = Dictionary(uniqueKeysWithValues: diff.insertions.compactMap {
            if case let .insert(offset, element, _) = $0 {
                return (offset, element)
            } else {
                return nil
            }
        })
        
        print("REMOVALS: \(removals)")
        print("INSERTIONS: \(insertions)")

        
        var result: [Fragment] = []
        var rIndex = 0, oIndex = 0

        while oIndex < original.count || rIndex < revised.count {
            if let removed = removals[oIndex] {
                result.append(.init(text: String(removed) + " ", kind: .deletion))
                oIndex += 1                                // skip only the old side
            } else if let inserted = insertions[rIndex] {
                result.append(.init(text: String(inserted) + " ", kind: .insertion))
                rIndex += 1                                // skip only the new side
            } else {
                result.append(.init(text: String(revised[rIndex]) + " ", kind: .equal))
                oIndex += 1;  rIndex += 1                  // advance both
            }
        }
        return result
    }

    var body: some View {
        HStack(spacing: 0) {
            pieces.reduce(Text("") ) { t, piece in
                t +
                Text(LocalizedStringKey(piece.text))
                    .foregroundColor(color(for: piece.kind))
                    .strikethrough(piece.kind == .deletion)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .font(.system(.body, design: .monospaced))
        .padding()
        .background(Color(.secondarySystemBackground))
        
    }

    private func color(for kind: Kind) -> Color {
        switch kind {
        case .equal:     return .primary
        case .insertion: return .green
        case .deletion:  return .red
        }
    }
}

#Preview {
    VStack {
        DiffView(old: "Hello, world!", new: "Hello")
        DiffView(old: "Hello, world! I love it!", new: banhMiRecipe.toText(), alignment: .leading)
        DiffView(old: "Hello, world! I love it!", new: """
            This is step 1.
            
            This is Step 2
            """, alignment: .leading)
        DiffView(
            old: """
            Levain
            25 g Bread Flour
            """,
            new: """
            **Levain**
            30 g **Bread Flour**
            Sugar
            """,
            alignment: .leading)
    }
    .frame(maxWidth: .infinity)
}

