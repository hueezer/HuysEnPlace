//
//  KitchenTimer.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/16/25.
//

import SwiftUI
import FoundationModels
import Playgrounds

@Generable
struct KitchenTimer: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    @Guide(description: "A short descriptive name of the timer based on the selected text and full text provided. Maximum of 3 words.")
    var name: String
    @Guide(description: "The duration in seconds.")
    var duration: TimeInterval
}

extension KitchenTimer {
    static func generateTimers(text: String) async -> [KitchenTimer] {
        let instructions = """
            From the text provided, create a timer with a name and duration. The name should be based on the text provided. Examples: "bake for 20 minutes" should have a name of "Bake" and a duration of 20 minutes.
            """


        let session = LanguageModelSession(instructions: instructions)


        do {
            let response = try await session.respond(to: text, generating: KitchenTimer.self)
            print("generateTimer response: \(response.content)")
            return [response.content]
        } catch {
            print(error)
        }
        
        
        return []
    }
    
    static func generateTimers(selectedText: String, step: Step) async -> [KitchenTimer] {
        let instructions = """
            From the text provided, create a timer with a name and duration. Use the Selected Text as the primary source for the name and duration. If that is not enough, more context is provided with the Full Text.
            """


        let session = LanguageModelSession(instructions: instructions)

        let text = """
            Selected text: \(selectedText)
            Full text: \(step.text)
            """

        do {
            let response = try await session.respond(to: text, generating: KitchenTimer.self)
            print("generateTimer response: \(response.content)")
            return [response.content]
        } catch {
            print(error)
        }
        
        
        return []
    }
    
    static func generateTimers(step: Step) async -> [KitchenTimer] {
        let instructions = """
            From the text provided, create a timer with a name and duration. Use the Selected Text as the primary source for the name and duration. If that is not enough, more context is provided with the Full Text.
            """


        let session = LanguageModelSession(instructions: instructions)

        let text = """
            \(step.text)
            """

        do {
            let response = try await session.respond(to: text, generating: KitchenTimer.self)
            print("generateTimer response: \(response.content)")
            return [response.content]
        } catch {
            print(error)
        }
        
        
        return []
    }
}

#Playground {
    let response1 = await KitchenTimer.generateTimers(selectedText: "20 minutes", step: .init(text: "Lightly oil work surface. Remove dough from bowl. Slap and fold the dough 4-6 times and form a ball. Cover and let rest for 20 minutes."))
    
    print(response1)
    
    let response2 = await KitchenTimer.generateTimers(step: .init(text: "Lightly oil work surface. Remove dough from bowl. Slap and fold the dough 4-6 times and form a ball. Cover and let rest for 20 minutes."))
    
    print(response2)
    
    let response3 = await KitchenTimer.generateTimers(step: .init(text: "In a stand mixer, mix on low speed for 7 minutes. Then 3 minutes on high speed. Continue mixing until gluten is fully developed. (Total mixing times will vary depending on mixer)."))
    
    print(response3)
}
