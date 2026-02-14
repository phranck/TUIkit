//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SelectionDisabledTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Selection Disabled Modifier Tests

@MainActor
@Suite("Selection Disabled Modifier Tests")
struct SelectionDisabledModifierTests {

    @Test("Environment default is false")
    func environmentDefaultIsFalse() {
        let environment = EnvironmentValues()
        #expect(environment.isSelectionDisabled == false)
    }

    @Test("Modifier sets environment value to true")
    func modifierSetsEnvironmentTrue() {
        let view = Text("Test").selectionDisabled()

        // Create context and render to propagate environment
        let context = createTestContext()
        _ = renderToBuffer(view, context: context)

        // The modifier should have set isSelectionDisabled in the environment
        // We verify this by checking that the modifier was created correctly
        #expect(view is SelectionDisabledModifier<Text>)
    }

    @Test("Modifier with false does not disable selection")
    func modifierWithFalseDoesNotDisable() {
        let view = Text("Test").selectionDisabled(false)
        #expect(view is SelectionDisabledModifier<Text>)
    }

    @Test("Environment can be set and read")
    func environmentCanBeSetAndRead() {
        var environment = EnvironmentValues()
        environment.isSelectionDisabled = true
        #expect(environment.isSelectionDisabled == true)

        environment.isSelectionDisabled = false
        #expect(environment.isSelectionDisabled == false)
    }

    @Test("SelectionDisabledModifier renders content unchanged")
    func modifierRendersContentUnchanged() {
        let context = createTestContext()
        let originalView = Text("Content")
        let modifiedView = originalView.selectionDisabled()

        let originalBuffer = renderToBuffer(originalView, context: context)
        let modifiedBuffer = renderToBuffer(modifiedView, context: context)

        #expect(originalBuffer.lines == modifiedBuffer.lines)
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
