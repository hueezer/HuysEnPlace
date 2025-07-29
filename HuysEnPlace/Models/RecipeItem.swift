//
//  RecipeItem.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/27/25.
//

import SwiftUI

struct RecipeItem: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String = ""
    var imageURL: String?
    var prompt: String?
    var recipe: Recipe?
}
