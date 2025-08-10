//
//  Message.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/6/25.
//

import SwiftUI
import FoundationModels

@Generable
struct GeneratedMessage: Codable {
    var text: String
}

struct Message: Identifiable, Codable {
    let id: String = UUID().uuidString
    var text: String
    let role: Role
}
