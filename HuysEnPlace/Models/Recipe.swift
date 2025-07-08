//
//  Recipe.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/3/25.
//

import SwiftUI
//import SwiftData

@Observable
class Recipe: Identifiable, Equatable, Codable {
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String = UUID().uuidString
    var title: String = ""
    
    var content: AttributedString = ""
    var ingredients: [Ingredient] = []
    
    var lastModified: Date = .now
    
    init(title: String = "", content: AttributedString = "", ingredients: [Ingredient] = []) {
        self.title = title
        self.content = content
        self.ingredients = ingredients
    }
    
    func toJson() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(self)
            let jsonString = String(data: data, encoding: .utf8)
            print("jsonString: ", jsonString)
            return jsonString
        } catch {
            print("Failed to encode Recipe to JSON: \(error)")
            return nil
        }
    }
}

//@Model
//final class Recipe: Identifiable {
//    var lastModified: Date
//    var name: String
//    @Relationship(deleteRule: .cascade)
//    var ingredients: [Ingredient]
//
//    var content: AttributedString {
//        get {
//            contentModel.value
//        }
//        set {
//            contentModel.value = newValue
//            lastModified = .now
//        }
//    }
//
//    @Relationship(deleteRule: .cascade)
//    private var contentModel: AttributedStringModel
//
//    @Attribute(.externalStorage)
//    var image: Data?
//
//    init(name: String, content: AttributedString, ingredients: [Ingredient]) {
//        self.name = name
//        self.ingredients = ingredients
//        self.lastModified = .now
//        self.contentModel = AttributedStringModel(value: content, scope: .recipe)
//    }
//
//    convenience init() {
//        self.init(name: "", content: "", ingredients: [])
//    }
//}
