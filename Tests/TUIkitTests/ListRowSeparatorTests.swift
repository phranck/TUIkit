//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ListRowSeparatorTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - List Row Separator Modifier Tests

@MainActor
@Suite("List Row Separator Modifier Tests")
struct ListRowSeparatorModifierTests {

    @Test("Modifier returns content unchanged")
    func modifierReturnsContentUnchanged() {
        let context = createTestContext()
        let originalView = Text("Content")
        let modifiedView = originalView.listRowSeparator(.hidden)

        let originalBuffer = renderToBuffer(originalView, context: context)
        let modifiedBuffer = renderToBuffer(modifiedView, context: context)

        #expect(originalBuffer.lines == modifiedBuffer.lines)
    }

    @Test("Modifier accepts all visibility options")
    func modifierAcceptsAllVisibilityOptions() {
        let view1 = Text("Test").listRowSeparator(.automatic)
        let view2 = Text("Test").listRowSeparator(.visible)
        let view3 = Text("Test").listRowSeparator(.hidden)

        #expect(view1 is ListRowSeparatorModifier<Text>)
        #expect(view2 is ListRowSeparatorModifier<Text>)
        #expect(view3 is ListRowSeparatorModifier<Text>)
    }

    @Test("Modifier accepts edge options")
    func modifierAcceptsEdgeOptions() {
        let view1 = Text("Test").listRowSeparator(.hidden, edges: .top)
        let view2 = Text("Test").listRowSeparator(.hidden, edges: .bottom)
        let view3 = Text("Test").listRowSeparator(.hidden, edges: .all)

        #expect(view1 is ListRowSeparatorModifier<Text>)
        #expect(view2 is ListRowSeparatorModifier<Text>)
        #expect(view3 is ListRowSeparatorModifier<Text>)
    }

    @Test("Visibility enum has all expected cases")
    func visibilityEnumHasAllCases() {
        let automatic: Visibility = .automatic
        let visible: Visibility = .visible
        let hidden: Visibility = .hidden

        #expect(automatic == .automatic)
        #expect(visible == .visible)
        #expect(hidden == .hidden)
    }

    @Test("VerticalEdge.Set is an OptionSet")
    func verticalEdgeSetIsOptionSet() {
        let top: VerticalEdge.Set = .top
        let bottom: VerticalEdge.Set = .bottom
        let all: VerticalEdge.Set = .all

        #expect(top.rawValue == 1)
        #expect(bottom.rawValue == 2)
        #expect(all.contains(.top))
        #expect(all.contains(.bottom))
    }

    @Test("VerticalEdge.Set can be combined")
    func verticalEdgeSetCanBeCombined() {
        let combined: VerticalEdge.Set = [.top, .bottom]
        #expect(combined == .all)
    }
}

// MARK: - Test Helpers

@MainActor
private func createTestContext(width: Int = 80, height: Int = 24) -> RenderContext {
    let focusManager = FocusManager()
    var environment = EnvironmentValues()
    environment.focusManager = focusManager

    return RenderContext(
        availableWidth: width,
        availableHeight: height,
        environment: environment,
        tuiContext: TUIContext()
    )
}
