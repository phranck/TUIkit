//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StateAlignmentTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("State SwiftUI Alignment")
struct StateAlignmentTests {

    @Test("init(initialValue:) matches init(wrappedValue:)")
    func initialValueInitializer() {
        let state = State(initialValue: 42)

        #expect(state.wrappedValue == 42)
    }

    @Test("Optional state starts as nil with the empty initializer")
    func optionalEmptyInitializer() {
        let state = State<Int?>()

        #expect(state.wrappedValue == nil)
    }
}
