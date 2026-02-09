//  TUIKit - Terminal UI Kit for Swift
//  EdgeInsetsTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - EdgeInsets Tests

@MainActor
@Suite("EdgeInsets Tests")
struct EdgeInsetsTests {

    @Test("EdgeInsets uniform value")
    func edgeInsetsUniform() {
        let insets = EdgeInsets(all: 3)
        #expect(insets.top == 3)
        #expect(insets.leading == 3)
        #expect(insets.bottom == 3)
        #expect(insets.trailing == 3)
    }

    @Test("EdgeInsets horizontal and vertical")
    func edgeInsetsHorizontalVertical() {
        let insets = EdgeInsets(horizontal: 2, vertical: 1)
        #expect(insets.top == 1)
        #expect(insets.leading == 2)
        #expect(insets.bottom == 1)
        #expect(insets.trailing == 2)
    }

    @Test("EdgeInsets is Equatable")
    func edgeInsetsEquatable() {
        let insetsA = EdgeInsets(all: 2)
        let insetsB = EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        #expect(insetsA == insetsB)
    }
}

// MARK: - Edge Tests

@MainActor
@Suite("Edge Tests")
struct EdgeTests {

    @Test("Edge.all contains all edges")
    func edgeAll() {
        #expect(Edge.all.contains(.top))
        #expect(Edge.all.contains(.leading))
        #expect(Edge.all.contains(.bottom))
        #expect(Edge.all.contains(.trailing))
    }

    @Test("Edge.horizontal contains leading and trailing")
    func edgeHorizontal() {
        #expect(Edge.horizontal.contains(.leading))
        #expect(Edge.horizontal.contains(.trailing))
        #expect(!Edge.horizontal.contains(.top))
        #expect(!Edge.horizontal.contains(.bottom))
    }

    @Test("Edge.vertical contains top and bottom")
    func edgeVertical() {
        #expect(Edge.vertical.contains(.top))
        #expect(Edge.vertical.contains(.bottom))
        #expect(!Edge.vertical.contains(.leading))
        #expect(!Edge.vertical.contains(.trailing))
    }
}
