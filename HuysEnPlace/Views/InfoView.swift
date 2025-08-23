//
//  InfoView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/16/25.
//

import SwiftUI
import FoundationModels

@Generable
struct GeneratedInfo: Codable {
    @Guide(description: """
    Break the content into clear sections with concise, non-redundant titles.
    The first section must be an Overview.
    Use normal markdown (paragraphs, bullet lists, numbered steps) by default.
    """)
    var content: [ContentSection]? = []
    
    @Guide(description: "Translation of the subject name in Vietnamese")
    var titleInVietnamese: String?
}

@Generable
struct ContentSection: Codable, Hashable {
    @Guide(description: "A short title for the section (3–6 words). Avoid repeating words across sections.")
    var title: String?

    @Guide(description: """
    The body of the section in markdown. Prefer paragraphs and lists. 
    Never try to format text as a table inside this field.
    """)
    var text: String?

    @Guide(description: """
    1) The section’s sole purpose is to compare items side-by-side, AND
    2) There are 2–6 columns with clear comparable attributes (e.g., spec, metric, measurement), AND
    3) There are ≥3 rows (i.e., multiple items being compared), AND
    4) At least 70% of the cells are short numeric/spec values (numbers, units, yes/no, version tags).

    If a table is used, ensure the section title contains a comparison cue like “Comparison,” “Specs,” or “Matrix.”
    """)
    var table: InfoTable?
    
    @Guide(description: "If a table would be useful in this section, set to true.")
    var includeTable: Bool?
}

@Generable
struct InfoTable: Codable, Hashable {
    @Guide(description: """
    Column names, 2–6 max. Keep them brief (1–3 words). Use units in the column header when applicable (e.g., Weight (g)).
    """)
    var columns: [String] = []

    @Guide(description: """
    Each row aligns with the columns. Provide ≥3 rows.
    Cells should be short values (numbers, units, ticks like Yes/No). 
    Do not include long sentences here.
    """)
    var rows: [[String]] = []
}

struct InfoView: View {
    var subjectName: String
    var context: String
    
    @State private var pageContent: String = ""
    @State private var info: GeneratedInfo.PartiallyGenerated?
    
    @State private var session = OpenAI(instructions: """
        <maximize_context_understanding>
        Be THOROUGH when gathering information. Make sure you have the FULL picture before replying.
        </maximize_context_understanding>
        
        ## Identity
        You a culinary encyclopedia. 
        Produce content that is interesting, very concise, and factual — the most engaging written culinary content ever.

        ## Style
        - Use markdown.
        - Italicize important phrases.
        - Use paragraphs and bullet/numbered lists by default.
        - The first section should always be an *Overview*.

        ## Sections
        - Keep section titles short (3–6 words) and non-redundant.
        - Avoid repeating words across sections.
        - Default to text most content.
        - Only use a table if the title clearly signals a comparison (e.g., “Comparison,” “Specs,” “Matrix”).
        
        ## Tables
        -- Add one or two tables where it makes the most sense, especaially when the content seems to be listing a lot of numbers. If a table is included make the text complementary and not redundant
        """
    )
    
    @State private var isLoading = true
    
    let line1 = (0..<5).map { _ in Int.random(in: 50...90) }
    let line2 = (0..<5).map { _ in Int.random(in: 50...90) }
    let line3 = (0..<5).map { _ in Int.random(in: 50...90) }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(subjectName.capitalized)
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .safeAreaPadding(.horizontal)
                
                Divider()
                
                if isLoading {
                    VStack(alignment: .leading) {
                        ParagraphLoadingPlaceholder(lines: line1)
                        ParagraphLoadingPlaceholder(lines: line2)
                        ParagraphLoadingPlaceholder(lines: line3)
                    }
                    .safeAreaPadding(.horizontal)
                }
                
                Text((info?.titleInVietnamese ?? "").capitalized)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .safeAreaPadding(.horizontal)
                
                ForEach(info?.content ?? [], id: \.self) { item in
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey((item.title?.capitalized ?? "").trimmingCharacters(in: .whitespacesAndNewlines)))
                            .bold()
                        Text(LocalizedStringKey((item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)))
//                        Text("\(item.includeTable ?? false ? "Table" : "No table")")
                        if item.includeTable ?? false {
                            if let table = item.table, let columns = table.columns, let rows = table.rows {
                                TableView(table: InfoTable(columns: columns, rows: rows))
                            }
                        }
                    }
                    .safeAreaPadding(.horizontal)
                }

                Text(LocalizedStringKey(pageContent))
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            let userMessage = ResponseInputMessageItem(
                id: UUID().uuidString,
                content: [
                    .input_text(ResponseInputText(text: """
                    Subject Name: \(subjectName)
                    Write some content on the subject.
                    Write in within the context of: \(context)
                """))
                ],
                role: .developer,
                status: .in_progress,
                type: .message
            )
            let input: [ResponseItem] = [
                .input_message(userMessage)
            ]
            
            do {
                let stream = try await session.streamResponse(input: input, generating: GeneratedInfo.self)
                for try await partial in stream {
                    print("PARTIAL PARTIAL: \(partial)")
                    if isLoading {
                        isLoading = false
                    }
                    info = partial
                }
            } catch {
                print("Streaming failed:", error)
            }

        }
    }
}


struct ParagraphLoadingPlaceholder: View {
    // Using an array and map:
    let lines: [Int]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 96, height: 18)
                .padding(.bottom, 8)
            VStack(alignment:.leading) {
                ForEach(lines, id: \.self) { barWidths in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 18)
                        .containerRelativeFrame(.horizontal, count: 100, span: barWidths, spacing: 0)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        InfoView(subjectName: "Ascorbic Acid", context: "This is being used in a banh mi recipe.")
    }
}

