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
        
//        print("original: \(original)")
//        print("revised: \(revised)")
        
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
        
//        print("REMOVALS: \(removals)")
//        print("INSERTIONS: \(insertions)")

        
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
        DiffView(old: "", new: """
            Prepare the levain: In a small jar, mix **50 g** of [Bread Flour](miseenplace://ingredients/bread-flour), **50 g** of [Water](miseenplace://ingredients/water) and **10 g** of mature [Sourdough Starter](miseenplace://ingredients/sourdough-starter) (100% hydration). Cover loosely and ferment at **26 °C** for **8–12 h** until doubled, domed and bubbly.
            Mix the final dough: In the bowl of a stand mixer, combine **210 g** of [Water](miseenplace://ingredients/water), **50 g** of beaten [Whole Egg](miseenplace://ingredients/egg), all the ripe levain (about **110 g**), **2 g** of [Sugar](miseenplace://ingredients/sugar), **2 g** of [Salt](miseenplace://ingredients/salt) and **1 g** of [Ascorbic Acid](miseenplace://ingredients/ascorbic-acid) (optional). Add **400 g** of [Bread Flour](miseenplace://ingredients/bread-flour) and mix with a dough hook on low for **5 min**, then medium-high for **3 min** until smooth with a thin windowpane.
            Lightly oil the work surface with [Vegetable Oil](miseenplace://ingredients/vegetable-oil). Transfer the dough, give **4–6** gentle slap-and-folds, shape into a ball, cover and rest **30 min** (fermentolyse).
            Bulk-ferment for **4–5 h** at **26 °C**, giving the dough two to three letter-folds every **60 min**. Aim for a **70–80%** rise and a light, airy feel.
            Optional flavor build: After the first **60–90 min** of bulk, you may cover and refrigerate the dough for **8–12 h** at **4 °C**. Next day, let it warm at room temp until puffy before proceeding.
            Divide into six **120 g** pieces. Pre-shape into loose balls, cover and bench-rest **20 min**.
            Shape each piece into a tight torpedo (see baguette-shaping references). Place seam-side-down on a lightly oiled baguette pan.
            Final proof at **26 °C** (oven with light on and a pan of warm water) for **3–3½ h**, misting the loaves lightly with water every **15 min**. They should expand **2.5–3×** and feel very light.
            Preheat the oven to **230 °C** (Bake, bottom heat or no fan) with two trays, one filled with lava rocks for steam.
            Bring a kettle of water to a boil. When loaves are ready, score with a lame, mist the surfaces, slide pans into the oven and carefully pour the boiling water over the lava rocks.
            Bake **10 min** without opening the door, then vent the steam and bake a further **7–9 min** until deep golden and very light in weight.
            Remove the Bánh Mì and cool on a rack. Cracks should begin to sing and appear after **5–10 min**; serve warm for the classic crisp-thin crust.
            """)
    }
    .frame(maxWidth: .infinity)
}

