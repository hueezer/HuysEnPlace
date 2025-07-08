//
//  DispatchingChanges.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/4/25.
//

import SwiftUI

struct DispatchingChanges<ID: Hashable, Input: Sendable & Equatable, Content: View>: View {
    private let id: ID
    private let content: (Input) -> Content
    private let input: Input
    private let duration: Duration
    @State private var dispatchedInput: Input?
    @State private var task: Task<Void, Never>?

    init(
        to input: Input,
        for duration: Duration = .seconds(1),
        id: ID,
        @ViewBuilder _ content: @escaping (Input) -> Content
    ) {
        self.id = id
        self.content = content
        self.input = input
        self.duration = duration
    }

    var body: some View {
        content(dispatchedInput ?? input)
            .onChange(of: id) {
                dispatchedInput = nil
            }
            .onChange(of: input, initial: true) {
                task?.cancel()

                guard dispatchedInput != nil else {
                    dispatchedInput = input
                    return
                }

                task = Task { [input, duration, $dispatchedInput] in
                    try? await Task.sleep(for: duration)
                    if !Task.isCancelled {
                        $dispatchedInput.wrappedValue = input
                    }
                }
            }
    }
}
