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

func keepMarkdownPhrasesTogether(
    in text: String,
    delim: Character = "_"
) -> String {

    // One pattern to rule them all — longest delimiters first
    //  ▸ **bold**      ▸ __bold__
    //  ▸ *italic*      ▸ _italic_
    //  ▸ `code`        ▸ ~~strike~~
    //  ▸ [link text](url)
    // Longest tokens first: [link](url), **bold**, __bold__, *italic*, _italic_, `code`, ~~strike~~
    let pattern = #"""
    (\[[^\]\n]+?\]\([^)]+\)|        # [visible text](url)
     \*\*[^*]+?\*\*| __[^_]+?__|   # **bold**  or  __bold__
     (?<!\*)\*[^*\n]+?\*(?!\*)|    # *italic* (but not **bold**)
     (?<!_)_[^_\n]+?_(?!_)|        # _italic_ (but not __bold__)
     `[^`]+?`   |                  # `code`
     ~~[^~]+?~~)                   # ~~strike~~
    """#
    let regex = try! NSRegularExpression(pattern: pattern,
                                         options: [.allowCommentsAndWhitespace])

    // Collect matches (in original text!) and process them from the tail
    var result = text
    let matches = regex.matches(in: text,
                                range: NSRange(text.startIndex..., in: text))
                    .reversed()

    for m in matches {
        guard let full = Range(m.range, in: result) else { continue }
        var segment = String(result[full])

        // Special case: markdown link — only mutate the [visible part]
        if segment.hasPrefix("[") {
            // Split once at the first closing bracket ]
            let parts = segment.split(separator: "]", maxSplits: 1,
                                      omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let visible = parts[0].dropFirst()          // remove “[”
            let newVis  = visible.replacingOccurrences(of: " ",
                                                       with: String(delim))
            segment = "[" + newVis + "]" + parts[1]     // rebuild
        } else {
            // Figure out the opening/closing token
            let opener: String =
                segment.hasPrefix("**") ? "**" :
                segment.hasPrefix("__") ? "__" :
                segment.hasPrefix("~~") ? "~~" :
                segment.hasPrefix("`")  ? "`"  :
                segment.hasPrefix("*")  ? "*"  : "_"

            let innerStart = segment.index(segment.startIndex,
                                           offsetBy: opener.count)
            let innerEnd   = segment.index(segment.endIndex,
                                           offsetBy: -opener.count)
            let innerRange = innerStart..<innerEnd
            let inner      = segment[innerRange]

            let replaced   = inner.replacingOccurrences(of: " ",
                                                        with: String(delim))
            segment = opener + replaced + opener
        }

        result.replaceSubrange(full, with: segment)
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
    
        let original = splitter(keepMarkdownPhrasesTogether(in: old))
        let revised = splitter(keepMarkdownPhrasesTogether(in: new))
        
        print("original: \(original)")
        print("revised: \(revised)")
        
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
                let prefix = result.last?.kind == .deletion ? " " : ""
                let fragment = Fragment(text: prefix + String(removed.replacing("_", with: " ")), kind: .deletion)
                result.append(fragment)
                oIndex += 1                                // skip only the old side
            } else if let inserted = insertions[rIndex] {
                let suffix = inserted == "\n" ? "" : " "
                let fragment = Fragment(text: String(inserted.replacing("_", with: " ")) + suffix, kind: .insertion)
                result.append(fragment)
                rIndex += 1                                // skip only the new side
            } else {
                let suffix = revised[rIndex] == "\n" ? "" : " "
                let fragment = Fragment(text: String(revised[rIndex].replacing("_", with: " ")) + suffix, kind: .equal)
                result.append(fragment)
                oIndex += 1;  rIndex += 1                  // advance both
            }
        }
        return result
    }

    var body: some View {
        HStack(spacing: 0) {
            let _ = print("PIECES: \(pieces)")
            pieces.enumerated().reduce(Text("")) { t, pair in
                let (index, piece) = pair
                return t +
                Text(LocalizedStringKey(piece.text))
                    .foregroundColor(color(for: piece.kind))
                    .strikethrough(piece.kind == .deletion) +
                Text(piece.kind == .deletion && index + 1 < pieces.count && pieces[index + 1].kind != .deletion ? " " : "")
                // Now you can use `index` as needed
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .font(.system(.subheadline, design: .monospaced))
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
            30 g **Bread Flour** and **Regular Flour**
            Sugar
            [Active Sourdough Starter](miseenplace://ingredients/active-sourdough-starter)
            """,
            alignment: .leading)
    }
    .frame(maxWidth: .infinity)
}

