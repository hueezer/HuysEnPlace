//
//  Message.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/6/25.
//

import SwiftUI
import FoundationModels

@Generable
struct Message: Identifiable, Codable {
    var id: String { UUID().uuidString }
    var text: String
}
