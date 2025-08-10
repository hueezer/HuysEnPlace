//
//  RecipeIngredientInfo.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/20/25.
//

import SwiftUI
import FoundationModels

struct RecipeIngredientInfo: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var overview: String
    var roleTitle: String
    var roleDetails: String
    var ingredient: Ingredient
}

@Generable
struct GeneratedRecipeIngredientInfo: Codable {
    @Guide(description: "The name of the ingredient")
    var name: String
    
    @Guide(description: "A short overview of the ingredient")
    var overview: String
    
    @Guide(description: "A role title for the ingredient for current recipe")
    var roleTitle: String
    
    @Guide(description: "Details on what role or function the ingredient has within the recipe")
    var roleDetails: String
    
    @Guide(description: "A full description of the ingredient that goes more in depth")
    var fullDescription: String
}

struct RecipeIngredientInfoView: View {
    var recipe: Recipe
    var ingredientQuantity: IngredientQuantity
//    var info: RecipeIngredientInfo
    
    @State private var infoState = RecipeIngredientInfo(name: "", overview: "", roleTitle: "", roleDetails: "", ingredient: Ingredient())
    @State private var description: String = ""
    
    @State private var session = OpenAISession(instructions: """
                    ## Identity

                    You contain all culinary knowledge in the world. Produce content that is both interesting, concise and factual. It should be the most interesting culinary book ever to exist.
                    
                    ## Outline
                    Include these sections:
                    - Overview (this should never be a list)
                    - Role Ingredient in the context of the recipe. Create a concise, relevant title for this section
                    - Description
                    - Any other interesting sections go here
                    
                    ## Format
                    Each section should have a title and should be bold.
                    Include a new line between the title and the body.
                    Sections should be no longer than 5 sentences.
                    Italicize any important information that should be emphasized.
                    Use lists with bullet points when needed.
                    Respond in markdown.
                    
                    ## Here is the markdown supported:
                    This is regular text.
                    * This is **bold** text, this is *italic* text, and this is ***bold, italic*** text.
                    ~~A strikethrough example~~
                    `Monospaced works too`
                    
                    Only use these supported markdown styles
                    """)
    
    var body: some View {
        ScrollView {
            AsyncImage(url: URL(string: "https://picsum.photos/200")) { image in
                image.resizable()
                    .aspectRatio(1, contentMode: .fit)
            } placeholder: {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(.gray.opacity(0.5))
                .aspectRatio(1, contentMode: .fit)
            }
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey(infoState.overview))
                    .font(.body)
//                Text(infoState.name)
//                    .font(.title)
//                    .bold()
//                Text("Overview")
//                    .font(.headline)
//                Text(infoState.overview)
//                    .font(.body)
//                Text(infoState.overview)
//                    .font(.body)
//                Text(infoState.roleTitle)
//                    .font(.headline)
//                Text(infoState.roleDetails)
//                    .font(.body)
//                Text("Description")
//                    .font(.headline)
//                Text(description)
//                    .font(.body)
//                Divider()
//                HStack {
//                    Text("Link:")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                    Text(infoState.ingredient.name)
//                        .font(.subheadline)
//                }
            }
            .padding()
        }
//        .task {
//            let prompt = """
//                Ingredient name: \(ingredientQuantity.ingredientText)
//                Recipe name: \(recipe.title)
//                """
//            
//            if let response = try? await OpenAISession(instructions: sharedInstructions).respondTest(to: prompt, generating: GeneratedRecipeIngredientInfo.self) {
//                infoState.name = response.name
//                infoState.overview = response.overview
//                infoState.roleTitle = response.roleTitle
//                infoState.roleDetails = response.roleDetails
//                description = response.fullDescription
//            }
//        }
        .task {
            let userMessage = ResponseInputMessageItem(
                id: UUID().uuidString,
                content: [
                    .input_text(ResponseInputText(text: """
                Ingredient name: \(ingredientQuantity.ingredientText)
                Recipe name: \(recipe.title)
                """))
                ],
                role: .user,
                status: .in_progress,
                type: .message
            )
            let input: [ResponseItem] = [
                .input_message(userMessage)
            ]
            
            do {
                let streamEvents = try await session.readStreamingResponse(input: input)
                for try await streamEvent in streamEvents {
                    switch streamEvent {
                        
                    case .responseCreatedEvent(let event):
                        print("responseCreated: \(event.response)")
                        if let text = event.response.output_text {
                            infoState.overview = text
                        }
                    case .responseCompletedEvent(let event):
                        print("responseCreated: \(event.response.output)")
                        for item in event.response.output {
                            switch item {
                            case .output_message(let message):
                                print("output_message: \(message)")
                                for content in message.content {
                                    switch content {
                                    case .output_text(let outputTextItem):
                                        infoState.overview = outputTextItem.text
                                    default:
                                        print("Default")
                                    }
                                }
                            default:
                                print("Default")
                            }
                        }
                    case .responseOutputTextDeltaEvent(let event):
                        print("responseOutputTextDeltaEvent: \(event)")
                        infoState.overview += event.delta
                        
                    }
                    
                }
            } catch {
                print("Streaming failed:", error)
            }

        }
    }
}

#Preview {
    
    RecipeIngredientInfoView(recipe: .init(title: "Banh Mi"), ingredientQuantity: .init(ingredientText: "Bread Flour"))
}
