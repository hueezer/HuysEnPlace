//
//  KitchenTimer.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/16/25.
//

import SwiftUI

struct KitchenTimer: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var duration: TimeInterval
}
