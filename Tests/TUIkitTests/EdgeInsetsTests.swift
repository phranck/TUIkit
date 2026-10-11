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

    @Test("Edge.Set.all contains all edges")
    func edgeAll() {
        #expect(Edge.Set.all.contains(.top))
        #expect(Edge.Set.all.contains(.leading))
        #expect(Edge.Set.all.contains(.bottom))
        #expect(Edge.Set.all.contains(.trailing))
    }

    @Test("Edge.Set.horizontal contains leading and trailing")
    func edgeHorizontal() {
        #expect(Edge.Set.horizontal.contains(.leading))
        #expect(Edge.Set.horizontal.contains(.trailing))
        #expect(!Edge.Set.horizontal.contains(.top))
        #expect(!Edge.Set.horizontal.contains(.bottom))
    }

    @Test("Edge.Set.vertical contains top and bottom")
    func edgeVertical() {
        #expect(Edge.Set.vertical.contains(.top))
        #expect(Edge.Set.vertical.contains(.bottom))
        #expect(!Edge.Set.vertical.contains(.leading))
        #expect(!Edge.Set.vertical.contains(.trailing))
    }
}
