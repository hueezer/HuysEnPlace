//
//  ModifyRecipeTool.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 8/14/25.
//

import SwiftUI
import FoundationModels

struct ModifyRecipeTool: Tool, Encodable, Sendable {
    var name: String = "modifyRecipe"
    let description = "Modifies a recipe based on input from the user."
    let type = "function"
    var onCall: @Sendable (GeneratedRecipe) -> Void = { _ in }
//    var session: OpenAISession? = nil
    
//    init(name: String = "modifyRecipe", session: OpenAISession? = nil, onCall: @Sendable @escaping (GeneratedRecipe) -> Void = { _ in }) {
//        print("previousResponseId init with session: \(session)")
//        self.name = name
//        self.session = session
//        self.onCall = onCall
//    }
    
    init(onCall: @Sendable @escaping (GeneratedRecipe) -> Void = { _ in }) {
        self.onCall = onCall
    }
    
    @Generable
    struct Arguments: Decodable, Sendable {
        @Guide(description: "How the recipe should be modified.")
        var prompt: String
        @Guide(description: "The recipe after being modified")
        var recipe: GeneratedRecipe
    }
    
//    func call(arguments: Arguments) async throws -> GeneratedRecipe? {
//        print("Called Modify Recipe Tool with args: \(arguments)")
//        let recipe = Recipe(from: arguments.recipe)
//        print("CALLING MODIFY RECIPE TOOL with ingredients: \(recipe.ingredients)")
//        let fullPrompt = """
//            Modify the following recipe acording to these intructions, while only modifying necessary text:
//            \(arguments.prompt)
//            Recipe:
//            \(String(describing: recipe.toJson()))
//            """
//        print("Full Prompt: \(fullPrompt)")
//        print("previousResponseId call session: \(String(describing: self.session))")
//        if let session = self.session {
//            do {
//                if let response = try await OpenAISession(instructions: sharedInstructions).respond(to: fullPrompt, generating: GeneratedRecipe.self) {
//                    print("previousResponseId: RESOPONSE: \(response)")
//                    onCall(response)
//                    return response
//                } else {
//                    print("NO TOOL SESSION previousResponseId")
//                }
//            } catch {
//                print("prviousResponseId error: \(error)")
//            }
//        } else {
//            
//        }
//
//        return nil
////        return generatedRecipeResponse
//    }
    
    func call(arguments: Arguments) async throws -> GeneratedRecipe? {
        print("Called Modify Recipe Tool with args: \(arguments)")
        let recipe = Recipe(from: arguments.recipe)
        print("CALLING MODIFY RECIPE TOOL with ingredients: \(recipe.ingredients.map { $0.items.map { $0.ingredientText }})")
        let fullPrompt = """
            <tool_preambles>
            - Always begin by rephrasing the user's goal in a friendly, clear, and concise manner, before calling any tools.
            - Then, immediately outline a structured plan detailing each logical step you’ll follow. - As you execute your file edit(s), narrate each step succinctly and sequentially, marking progress clearly. 
            - Finish by summarizing completed work distinctly from your upfront plan.
            </tool_preambles>
            Modify the following recipe acording to these intructions, while only modifying necessary text:
            \(arguments.prompt)
            Recipe:
            \(String(describing: Recipe(from: arguments.recipe).toJson()))

            """
        print("Full Prompt: \(fullPrompt)")
//        print("previousResponseId call session: \(String(describing: self.session))")
        onCall(arguments.recipe)
//        do {
//            if let response = try await OpenAI(instructions: sharedInstructions).respond(to: fullPrompt, generating: GeneratedRecipe.self) {
//                print("previousResponseId: RESOPONSE: \(response)")
//                onCall(response)
//                return response
//            } else {
//                print("NO TOOL SESSION previousResponseId")
//            }
//        } catch {
//            print("prviousResponseId error: \(error)")
//        }

        return arguments.recipe
//        return generatedRecipeResponse
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case type
        case parameters
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(type, forKey: .type)
        
        try container.encode(Arguments.generationSchema, forKey: .parameters)
    }
}
