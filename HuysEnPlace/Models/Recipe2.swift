//
//  Recipe2.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/9/25.
//

import SwiftUI

@Observable
class Recipe2: Identifiable, Equatable, Codable {
    static func == (lhs: Recipe2, rhs: Recipe2) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String = UUID().uuidString
    var title: String = ""
    var content: AttributedString = ""
    var ingredients: [Ingredient] = []
    
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

extension Recipe2 {
    
    enum RecipeError: Error {
        case fileNotFound
        case decodingFailed
    }
    /// Initialize a Recipe from a JSON file at the given URL.
    /// - Parameter url: The file URL pointing to the JSON file.
    /// - Throws: An error if reading or decoding fails.
    /// - Returns: A Recipe instance decoded from the file.
    static func fromJsonFile(at url: URL) throws -> Recipe2 {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Recipe2.self, from: data)
    }
    
    static func fromJsonFile(name: String) throws -> Recipe2 {
        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            do {
                let recipe = try Recipe2.fromJsonFile(at: url)
                print(recipe.title) // or do something with the recipe
                return recipe
            } catch {
                print("Failed to load recipe: \(error)")
                throw RecipeError.decodingFailed
            }
        } else {
            throw RecipeError.fileNotFound
        }
    }
}
