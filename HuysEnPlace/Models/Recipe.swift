//
//  Recipe2.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/9/25.
//

import SwiftUI
import FoundationModels

@Observable
class Recipe: Identifiable, Equatable, Codable, Hashable {
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id: String = UUID().uuidString
    var title: String = ""
    var content: AttributedString = ""
    var ingredients: [IngredientList] = []
    
    var steps: [Step] = []
    
    init(id: String = UUID().uuidString, title: String = "", content: AttributedString = "", ingredients: [IngredientList] = [], steps: [Step] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.ingredients = ingredients
        self.steps = steps
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title = "_title"
        case content = "_content"
        case ingredients = "_ingredients"
        case steps = "_steps"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content, configuration: AttributeScopes.RecipeModelAttributes.self)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(steps, forKey: .steps)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(AttributedString.self, forKey: .content, configuration: AttributeScopes.RecipeModelAttributes.self)
        ingredients = try container.decode([IngredientList].self, forKey: .ingredients)
        steps = try container.decode([Step].self, forKey: .steps)
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

@Generable
struct GeneratedRecipe: Codable {
    let title: String
    let ingredients: [IngredientList]
    let steps: [GeneratedStep]
}

@Generable
struct IngredientQuantity: Codable, Identifiable {
    var id: String = UUID().uuidString
    @Guide(description: "Amount and quantity in grams. Example: 30 g")
    var quantity: String = ""
    var ingredientText: String = ""
    var note: String = ""
//    var ingredient: Ingredient?
}

@Generable
struct IngredientList: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String = ""
    var items: [IngredientQuantity] = []
}

@Generable
struct GeneratedStep: Codable {
    var text: String = ""
}

extension Recipe {
    
    enum RecipeError: Error {
        case fileNotFound
        case decodingFailed
    }
    /// Initialize a Recipe from a JSON file at the given URL.
    /// - Parameter url: The file URL pointing to the JSON file.
    /// - Throws: An error if reading or decoding fails.
    /// - Returns: A Recipe instance decoded from the file.
    static func fromJsonFile(at url: URL) throws -> Recipe {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Recipe.self, from: data)
    }
    
    static func fromJsonFile(name: String) throws -> Recipe {
        if let url = Bundle.main.url(forResource: name, withExtension: "json") {
            do {
                let recipe = try Recipe.fromJsonFile(at: url)
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

