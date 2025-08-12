//
//  Step.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/17/25.
//

import SwiftUI

struct Step: Codable, Identifiable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var text: String = ""
    var ingredients: [String] = []
    var timers: [KitchenTimer] = []

    static func == (lhs: Step, rhs: Step) -> Bool {
        lhs.text == rhs.text
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(text)
        hasher.combine(ingredients)
        // Hash timers by their id to avoid requiring KitchenTimer to be Hashable
        for timer in timers {
            hasher.combine(timer.id)
        }
    }
}
