//
//  Step.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/17/25.
//

import SwiftUI

struct Step: Codable, Identifiable {
    var id: String = UUID().uuidString
    var text: String = ""
    var ingredients: [String] = []
    var timers: [KitchenTimer] = []
}
