//
//  Response.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/23/25.
//


import SwiftUI

struct Response: Identifiable, Codable {
    var id: String
    var status: Status
    var output: [ResponseItem]
    var previous_response_id: String?
    
    enum Status: String, Codable {
        case completed
        case failed
        case in_progress
        case incomplete
    }
}

enum Role: String, Codable {
    case user
    case assistant
    case developer
}

enum ResponseStatus: String, Codable {
    case in_progress
    case completed
    case incomplete
}

enum ResponseItem: Codable, Identifiable {
    case input_message(ResponseInputMessageItem)
    case output_message(ResponseOutputMessage)
    case function_call(ResponseFunctionToolCall)
    case function_call_output(ResponseFunctionToolCallOutput)
    case web_search_call(ResponseWebSearchCall)
    
    var id: String {
        switch self {
        case .input_message(let inputMessage):
            return inputMessage.id
        case .output_message(let outputMessage):
            return outputMessage.id
        case .function_call(let functionCall):
            return functionCall.id
        case .function_call_output(let functionCallOutput):
            return functionCallOutput.id ?? UUID().uuidString
        case .web_search_call(let webSeachCall):
            return webSeachCall.id
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case role
    }
    
    enum ResponseItemType: String, Codable {
        case message
        case function_call
        case function_call_output
        case web_search_call
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ResponseItemType.self, forKey: .type)
        let singleValueContainer = try decoder.singleValueContainer()
        
        // Check role to determine the type of message
        let role = try container.decodeIfPresent(Role.self, forKey: .role)
        
        switch type {
        case .message:
            if role == .assistant {
                let value = try singleValueContainer.decode(ResponseOutputMessage.self)
                self = .output_message(value)
            } else {
                let value = try singleValueContainer.decode(ResponseInputMessageItem.self)
                self = .input_message(value)
            }
        case .function_call:
            let value = try singleValueContainer.decode(ResponseFunctionToolCall.self)
            self = .function_call(value)
        case .function_call_output:
            let value = try singleValueContainer.decode(ResponseFunctionToolCallOutput.self)
            self = .function_call_output(value)
        case .web_search_call:
            let value = try singleValueContainer.decode(ResponseWebSearchCall.self)
            self = .web_search_call(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .input_message(let value):
            try container.encode(ResponseItemType.message, forKey: .type)
            try container.encode(value.role, forKey: .role)
            try value.encode(to: encoder)
        case .output_message(let value):
            try container.encode(ResponseItemType.message, forKey: .type)
            try container.encode(value.role.rawValue, forKey: .role)
            try value.encode(to: encoder)
        case .function_call(let value):
            try container.encode(ResponseItemType.function_call, forKey: .type)
            try value.encode(to: encoder)
        case .function_call_output(let value):
            try container.encode(ResponseItemType.function_call_output, forKey: .type)
            try value.encode(to: encoder)
        case .web_search_call(let value):
            try container.encode(ResponseItemType.web_search_call, forKey: .type)
            try value.encode(to: encoder)
        }
    }
    
    func asDictionary() -> [String: Any] {
        switch self {
        case .input_message(let inputMessage):
            let contentArray: [[String: Any]] = inputMessage.content.map { item in
                switch item {
                case .input_text(let text):
                    return ["type": text.type.rawValue, "text": text.text]
                case .input_image(let image):
                    var dict: [String: Any] = ["type": image.type.rawValue]
                    dict["detail"] = "\(image.detail)"
                    if let url = image.image_url {
                        dict["image_url"] = url
                    }
                    if let fileID = image.file_id {
                        dict["file_id"] = fileID
                    }
                    return dict
                case .input_file(let file):
                    var dict: [String: Any] = ["type": file.type.rawValue]
                    if let data = file.file_data {
                        dict["file_data"] = data
                    }
                    if let id = file.file_id {
                        dict["file_id"] = id
                    }
                    if let name = file.filename {
                        dict["filename"] = name
                    }
                    return dict
                }
            }
            return ["role": inputMessage.role.rawValue, "content": contentArray]

        case .output_message(let outputMessage):
            let contentArray: [[String: Any]] = outputMessage.content.map { item in
                switch item {
                case .output_text(let text):
                    return ["type": text.type.rawValue, "text": text.text]
                case .output_refusal(let refusal):
                    return ["type": refusal.type.rawValue, "text": refusal.text]
                }
            }
            return ["role": outputMessage.role.rawValue, "content": contentArray]
        case .function_call(let value):
            return [
                "type": "function_call",
                "id": value.id,
                "call_id": value.call_id,
                "name": value.name,
                "arguments": value.arguments,
                "status": value.status.rawValue
            ]
        case .function_call_output(let value):
            return [
                "type": "function_call_output",
                "id": value.id ?? "",
                "call_id": value.call_id,
                "output": value.output,
                "status": value.status?.rawValue as Any
            ]
        case .web_search_call(let value):
            return [
                "type": "web_search_call",
                "id": value.id,
                "status": value.status.rawValue
            ]
        }
    }
}

struct ResponseInputMessageItem: Identifiable, Codable {
    enum MessageType: String, Codable {
        case message
    }
    var id: String
    var content: [ResponseInputContent]
    var role: Role
    var status: ResponseStatus?
    let type: MessageType?
}

enum ResponseInputContent: Codable {
    case input_text(ResponseInputText)
    case input_image(ResponseInputImage)
    case input_file(ResponseInputFile)
    
    enum CodingKeys: String, CodingKey {
        case type
    }

    enum ContentType: String, Codable {
        case input_text
        case input_image
        case input_file
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        let singleValueContainer = try decoder.singleValueContainer()

        switch type {
        case .input_text:
            let value = try singleValueContainer.decode(ResponseInputText.self)
            self = .input_text(value)
        case .input_image:
            let value = try singleValueContainer.decode(ResponseInputImage.self)
            self = .input_image(value)
        case .input_file:
            let value = try singleValueContainer.decode(ResponseInputFile.self)
            self = .input_file(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .input_text(let value):
            try container.encode(ContentType.input_text, forKey: .type)
            try value.encode(to: encoder)
        case .input_image(let value):
            try container.encode(ContentType.input_image, forKey: .type)
            try value.encode(to: encoder)
        case .input_file(let value):
            try container.encode(ContentType.input_file, forKey: .type)
            try value.encode(to: encoder)
        }
    }
}

struct ResponseInputText: Codable {
    enum InputType: String, Codable {
        case input_text
    }
    
    let type: InputType
    let text: String
    
    init(text: String) {
        self.type = .input_text
        self.text = text
    }
}

struct ResponseInputImage: Codable {
    enum InputType: String, Codable {
        case input_image
    }
    
    enum Detail: Codable {
        case high
        case low
        case auto
    }

    let type: InputType
    let detail: Detail
    let file_id: String?
    let image_url: String?
}

struct ResponseInputFile: Codable {
    enum InputType: String, Codable {
        case input_file
    }
    
    enum Detail: Codable {
        case high
        case low
        case auto
    }

    let type: InputType
    let file_data: String?
    let file_id: String?
    let filename: String?
}

struct ResponseOutputMessage: Identifiable, Codable {

    enum MessageType: String, Codable {
        case message
    }
    
    enum RoleType: String, Codable {
        case assistant
    }

    let id: String
    let content: [ResponseOutputContent]
    let role: RoleType
    let status: ResponseStatus
    let type: MessageType
}

enum ResponseOutputContent: Codable {
    case output_text(ResponseOutputText)
    case output_refusal(ResponseOutputRefusal)
    
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    enum ContentType: String, Codable {
        case output_text
        case output_refusal
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch type {
        case .output_text:
            let value = try singleValueContainer.decode(ResponseOutputText.self)
            self = .output_text(value)
        case .output_refusal:
            let value = try singleValueContainer.decode(ResponseOutputRefusal.self)
            self = .output_refusal(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .output_text(let value):
            try container.encode(ContentType.output_text, forKey: .type)
            try value.encode(to: encoder)
        case .output_refusal(let value):
            try container.encode(ContentType.output_refusal, forKey: .type)
            try value.encode(to: encoder)
        }
    }
}

struct ResponseOutputText: Codable {
    enum OutputType: String, Codable {
        case output_text
    }
    
    let type: OutputType
    let text: String
}

struct ResponseOutputRefusal: Codable {
    enum OutputType: String, Codable {
        case output_refusal
    }
    
    let type: OutputType
    let text: String
}

struct ResponseFunctionToolCall: Identifiable, Codable {

    enum MessageType: String, Codable {
        case function_call
    }
    
    let type: MessageType
    let id: String
    let call_id: String
    let name: String
    let arguments: String
    let status: ResponseStatus
    
    var decodedArguments: [String: Any] {
        guard let data = arguments.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return [:]
        }
        return dictionary
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case id
        case call_id
        case name
        case arguments
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(MessageType.self, forKey: .type)
        id = try container.decode(String.self, forKey: .id)
        call_id = try container.decode(String.self, forKey: .call_id)
        name = try container.decode(String.self, forKey: .name)
        arguments = try container.decode(String.self, forKey: .arguments)

        status = try container.decode(ResponseStatus.self, forKey: .status)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(call_id, forKey: .call_id)
        try container.encode(name, forKey: .name)

        let data = try JSONSerialization.data(withJSONObject: arguments, options: [])
        let jsonString = String(data: data, encoding: .utf8) ?? "{}"
        try container.encode(jsonString, forKey: .arguments)

        try container.encode(status, forKey: .status)
    }
}

struct ResponseFunctionToolCallOutput: Identifiable, Codable {
    enum MessageType: String, Codable {
        case function_call_output
    }
    
    let type: MessageType
    let id: String?
    let call_id: String
    let output: String
    let status: ResponseStatus?
    
    enum CodingKeys: String, CodingKey {
        case type
        case id
        case call_id
        case output
        case status
    }
    
    init(id: String? = nil, call_id: String, output: String, status: ResponseStatus? = nil) {
        self.type = .function_call_output
        self.id = id
        self.call_id = call_id
        self.output = output
        self.status = status
    }
}

struct ResponseWebSearchCall: Identifiable, Codable {
    enum MessageType: String, Codable {
        case web_search_call
    }
    
    let type: MessageType
    let id: String
    let status: ResponseStatus
    
    enum CodingKeys: String, CodingKey {
        case type
        case id
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(MessageType.self, forKey: .type)
        id = try container.decode(String.self, forKey: .id)
        status = try container.decode(ResponseStatus.self, forKey: .status)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(status, forKey: .status)
    }
}
