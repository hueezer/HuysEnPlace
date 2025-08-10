//
//  Ingredient.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/3/25.
//

import SwiftUI
import FoundationModels
import Playgrounds

@Generable
struct Ingredient: Identifiable, Equatable, Codable {
    var id: String = UUID().uuidString
    var name: String = ""
    var description: String = ""
}

extension Ingredient {
    static func generate(text: String) async -> Ingredient? {
        let instructions = """
            From the text provided, generate ingredients.
            """


        let session = LanguageModelSession(instructions: instructions)


        do {
            let response = try await session.respond(to: text, generating: Ingredient.self)
            return response.content
        } catch {
            print(error)
            return nil
        }
    }
    
    
}


#Playground {
//    let encoder = JSONEncoder()
//    let data = try encoder.encode(Ingredient.generationSchema)
//    let jsonString = String(data: data, encoding: .utf8)
//    
//    let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//    
//    let response = try await Ingredient.generateWithOpenAI(text: "Carrots")
    

}

