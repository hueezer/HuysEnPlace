//
//  Ingredient.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/3/25.
//

import SwiftUI

struct Ingredient: Identifiable, Equatable, Codable {
    var id: String = UUID().uuidString
    var name: String
}
