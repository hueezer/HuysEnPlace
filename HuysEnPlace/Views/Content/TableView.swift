//
//  TableView.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/22/25.
//

import SwiftUI

struct TableView: View {
    var table: InfoTable
//    @Binding var columns: [String]
//    @Binding var rows: [[String]]
    
    var columnContentLengths: [Int] {
        (0..<table.columns.count).map { columnIndex in
            table.rows.compactMap { row -> Int? in
                guard row.indices.contains(columnIndex) else { return nil }
                return row[columnIndex].split { $0.isWhitespace }.count
            }.max() ?? 0
        }
    }
    
    
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .center, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    HStack {
                        ForEach(Array(table.columns.enumerated()), id: \.element) { colIndex, column in
                            let hasLongContent = columnContentLengths[colIndex] > 3
                            Text(column)
                                .bold()
                                .frame(maxWidth: 200)
                                .frame(maxHeight: .infinity)
                                .frame(width: hasLongContent ? UIScreen.main.bounds.size.width*0.5 :  UIScreen.main.bounds.size.width*0.25)
                            
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                                .padding(8)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .font(.caption2)
                
                ForEach(Array(table.rows.enumerated()), id: \.element) { rowIndex, row in
                    GridRow {
                        HStack {
                            ForEach(Array(row.enumerated()), id: \.element) { cellIndex, cell in
                                var hasLongContent = columnContentLengths[cellIndex] > 3
                                Text(cell)
                                    .frame(maxWidth: 200)
                                    .frame(maxHeight: .infinity)
                                    .frame(width: hasLongContent ? UIScreen.main.bounds.size.width*0.5 :  UIScreen.main.bounds.size.width*0.25)
                                
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .padding(8)
                                    .multilineTextAlignment(.center)
                                
                            }
                        }
                        .background((rowIndex % 2 == 0) ? Color.gray.opacity(0.4) : Color.gray.opacity(0.1))
                    }
                    
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(style: StrokeStyle(lineWidth: 1)))
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
//        .defaultScrollAnchor(table.columns.count > 2 ? .leading : .center)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .font(.footnote)
        .fontWeight(.light)
    }
}

#Preview {
    @Previewable var table = InfoTable(columns: ["Cut", "Temperature (°C)", "Time (hours)", "Notes"], rows: [
        ["Breast", "60–65", "1.5–4", "Juicy & tender; lower temp for very soft"],
        ["Thighs", "70–75", "1–4", "Rich flavor; 75°C for shreddable texture. I'm just adding more content here for testing."],
        ["Drumsticks", "75", "4–6", "Best fall-off-bone at higher temp"],
        ["Wings", "75", "2–4", "Tender and easy to debone"],
        ["Winglets", "75", "2–4", "Tender and easy to debone"]
    ])
    
    @Previewable var table2 = InfoTable(columns: ["Cut", "Temperature (°C)", "Time (hours)"], rows: [
        ["Breast", "60–65", "1.5–4"],
    ])
    
    @Previewable var table3 = InfoTable(columns: ["Cut", "Time & Temperature"], rows: [
        ["Whole Leg", "3–5 hr at 75°C – For shreddable results, go longer"],
        ["Chicken Breast", "1.5–4 hr at 62°C – Lower times = juicier"],
        ["Chicken Thigh", "1–4 hr at 72°C – Rich flavor develops with time"],
        ["Beef Ribeye", "2–3 hr at 54°C – Medium-rare, tender"],
        ["Beef Brisket", "24–36 hr at 62°C – Super tender & sliceable"],
        ["Beef", "24–36 hr at 62°C – Super tender & sliceable"],
    ])
    ScrollView {
        VStack {
            TableView(table: table)
            TableView(table: table2)
            TableView(table: table3)
        }
    }
    .safeAreaPadding()
}

