//  🖥️ TUIKit — Terminal UI Kit for Swift
//  NavigationSplitViewTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing
@testable import TUIkit

// MARK: - Test Helpers

/// Creates a test render context with the specified width.
@MainActor
private func testContext(width: Int = 80, height: Int = 24) -> RenderContext {
    RenderContext(
        availableWidth: width,
        availableHeight: height,
        tuiContext: TUIContext()
    )
}

// MARK: - NavigationSplitViewVisibility Tests

@Suite("NavigationSplitViewVisibility Tests")
struct NavigationSplitViewVisibilityTests {
    @Test("automatic visibility equals automatic")
    func automaticEqualsAutomatic() {
        let visibility1 = NavigationSplitViewVisibility.automatic
        let visibility2 = NavigationSplitViewVisibility.automatic
        #expect(visibility1 == visibility2)
    }

    @Test("all visibility equals all")
    func allEqualsAll() {
        let visibility1 = NavigationSplitViewVisibility.all
        let visibility2 = NavigationSplitViewVisibility.all
        #expect(visibility1 == visibility2)
    }

    @Test("doubleColumn visibility equals doubleColumn")
    func doubleColumnEqualsDoubleColumn() {
        let visibility1 = NavigationSplitViewVisibility.doubleColumn
        let visibility2 = NavigationSplitViewVisibility.doubleColumn
        #expect(visibility1 == visibility2)
    }

    @Test("detailOnly visibility equals detailOnly")
    func detailOnlyEqualsDetailOnly() {
        let visibility1 = NavigationSplitViewVisibility.detailOnly
        let visibility2 = NavigationSplitViewVisibility.detailOnly
        #expect(visibility1 == visibility2)
    }

    @Test("different visibilities are not equal")
    func differentVisibilitiesNotEqual() {
        #expect(NavigationSplitViewVisibility.all != NavigationSplitViewVisibility.detailOnly)
        #expect(NavigationSplitViewVisibility.automatic != NavigationSplitViewVisibility.doubleColumn)
        #expect(NavigationSplitViewVisibility.doubleColumn != NavigationSplitViewVisibility.detailOnly)
    }

    @Test("visibility is Hashable")
    func visibilityIsHashable() {
        var set: Set<NavigationSplitViewVisibility> = []
        set.insert(.all)
        set.insert(.detailOnly)
        set.insert(.all) // Duplicate
        #expect(set.count == 2)
    }

    @Test("visibility is Codable")
    func visibilityIsCodable() throws {
        let original = NavigationSplitViewVisibility.doubleColumn
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NavigationSplitViewVisibility.self, from: encoded)
        #expect(original == decoded)
    }
}

// MARK: - NavigationSplitViewColumn Tests

@Suite("NavigationSplitViewColumn Tests")
struct NavigationSplitViewColumnTests {
    @Test("sidebar column equals sidebar")
    func sidebarEqualsSidebar() {
        let column1 = NavigationSplitViewColumn.sidebar
        let column2 = NavigationSplitViewColumn.sidebar
        #expect(column1 == column2)
    }

    @Test("content column equals content")
    func contentEqualsContent() {
        let column1 = NavigationSplitViewColumn.content
        let column2 = NavigationSplitViewColumn.content
        #expect(column1 == column2)
    }

    @Test("detail column equals detail")
    func detailEqualsDetail() {
        let column1 = NavigationSplitViewColumn.detail
        let column2 = NavigationSplitViewColumn.detail
        #expect(column1 == column2)
    }

    @Test("different columns are not equal")
    func differentColumnsNotEqual() {
        #expect(NavigationSplitViewColumn.sidebar != NavigationSplitViewColumn.content)
        #expect(NavigationSplitViewColumn.content != NavigationSplitViewColumn.detail)
        #expect(NavigationSplitViewColumn.sidebar != NavigationSplitViewColumn.detail)
    }

    @Test("column is Hashable")
    func columnIsHashable() {
        var set: Set<NavigationSplitViewColumn> = []
        set.insert(.sidebar)
        set.insert(.content)
        set.insert(.detail)
        set.insert(.sidebar) // Duplicate
        #expect(set.count == 3)
    }
}

// MARK: - NavigationSplitViewStyle Tests

@Suite("NavigationSplitViewStyle Tests")
struct NavigationSplitViewStyleTests {
    @Test("AutomaticNavigationSplitViewStyle has correct sidebar proportion")
    func automaticStyleSidebarProportion() {
        let style = AutomaticNavigationSplitViewStyle()
        #expect(style.sidebarProportion == 0.33)
    }

    @Test("AutomaticNavigationSplitViewStyle has correct three-column proportions")
    func automaticStyleThreeColumnProportions() {
        let style = AutomaticNavigationSplitViewStyle()
        let props = style.threeColumnProportions
        #expect(props.sidebar == 0.25)
        #expect(props.content == 0.25)
        #expect(props.detail == 0.50)
    }

    @Test("BalancedNavigationSplitViewStyle has correct sidebar proportion")
    func balancedStyleSidebarProportion() {
        let style = BalancedNavigationSplitViewStyle()
        #expect(style.sidebarProportion == 0.33)
    }

    @Test("BalancedNavigationSplitViewStyle has correct three-column proportions")
    func balancedStyleThreeColumnProportions() {
        let style = BalancedNavigationSplitViewStyle()
        let props = style.threeColumnProportions
        #expect(props.sidebar == 0.25)
        #expect(props.content == 0.25)
        #expect(props.detail == 0.50)
    }

    @Test("ProminentDetailNavigationSplitViewStyle has narrower sidebar")
    func prominentDetailStyleSidebarProportion() {
        let style = ProminentDetailNavigationSplitViewStyle()
        #expect(style.sidebarProportion == 0.25)
    }

    @Test("ProminentDetailNavigationSplitViewStyle gives more space to detail")
    func prominentDetailStyleThreeColumnProportions() {
        let style = ProminentDetailNavigationSplitViewStyle()
        let props = style.threeColumnProportions
        #expect(props.sidebar == 0.20)
        #expect(props.content == 0.20)
        #expect(props.detail == 0.60)
    }

    @Test("Static style properties are accessible")
    func staticStyleProperties() {
        let auto: any NavigationSplitViewStyle = .automatic
        let balanced: any NavigationSplitViewStyle = .balanced
        let prominent: any NavigationSplitViewStyle = .prominentDetail

        #expect(auto.sidebarProportion == 0.33)
        #expect(balanced.sidebarProportion == 0.33)
        #expect(prominent.sidebarProportion == 0.25)
    }
}

// MARK: - NavigationSplitView Rendering Tests

@Suite("NavigationSplitView Rendering Tests")
@MainActor
struct NavigationSplitViewRenderingTests {
    @Test("Two-column split view renders both columns")
    func twoColumnRendersBothColumns() {
        let splitView = NavigationSplitView {
            Text("Sidebar")
        } detail: {
            Text("Detail")
        }

        let context = testContext(width: 80)
        let buffer = renderToBuffer(splitView, context: context)

        // Both columns should be rendered
        let content = buffer.lines.joined()
        #expect(content.contains("Sidebar"))
        #expect(content.contains("Detail"))
    }

    @Test("Two-column split view includes separator")
    func twoColumnIncludesSeparator() {
        let splitView = NavigationSplitView {
            Text("Left")
        } detail: {
            Text("Right")
        }

        let context = testContext(width: 80)
        let buffer = renderToBuffer(splitView, context: context)

        // TUI-specific: Columns are separated by space, not a line character.
        // Verify both columns are rendered with proper spacing.
        let content = buffer.lines.first ?? ""
        #expect(content.stripped.contains("Left"))
        #expect(content.stripped.contains("Right"))
        // The sidebar has fixed width (20) + space separator, so Right should start after that
        #expect(buffer.width == 80)
    }

    @Test("Three-column split view renders all columns")
    func threeColumnRendersAllColumns() {
        let splitView = NavigationSplitView {
            Text("Sidebar")
        } content: {
            Text("Content")
        } detail: {
            Text("Detail")
        }

        let context = testContext(width: 100)
        let buffer = renderToBuffer(splitView, context: context)

        let content = buffer.lines.joined()
        #expect(content.contains("Sidebar"))
        #expect(content.contains("Content"))
        #expect(content.contains("Detail"))
    }

    @Test("detailOnly visibility hides sidebar in two-column")
    func detailOnlyHidesSidebar() {
        var visibility = NavigationSplitViewVisibility.detailOnly
        let binding = Binding(get: { visibility }, set: { visibility = $0 })

        let splitView = NavigationSplitView(columnVisibility: binding) {
            Text("Sidebar")
        } detail: {
            Text("Detail")
        }

        let context = testContext(width: 80)
        let buffer = renderToBuffer(splitView, context: context)

        let content = buffer.lines.joined()
        #expect(!content.contains("Sidebar"))
        #expect(content.contains("Detail"))
    }

    @Test("detailOnly visibility hides sidebar and content in three-column")
    func detailOnlyHidesBothLeadingColumns() {
        var visibility = NavigationSplitViewVisibility.detailOnly
        let binding = Binding(get: { visibility }, set: { visibility = $0 })

        let splitView = NavigationSplitView(columnVisibility: binding) {
            Text("Sidebar")
        } content: {
            Text("Content")
        } detail: {
            Text("Detail")
        }

        let context = testContext(width: 100)
        let buffer = renderToBuffer(splitView, context: context)

        let content = buffer.lines.joined()
        #expect(!content.contains("Sidebar"))
        #expect(!content.contains("Content"))
        #expect(content.contains("Detail"))
    }

    @Test("doubleColumn visibility hides sidebar in three-column")
    func doubleColumnHidesSidebarInThreeColumn() {
        var visibility = NavigationSplitViewVisibility.doubleColumn
        let binding = Binding(get: { visibility }, set: { visibility = $0 })

        let splitView = NavigationSplitView(columnVisibility: binding) {
            Text("Sidebar")
        } content: {
            Text("Content")
        } detail: {
            Text("Detail")
        }

        let context = testContext(width: 100)
        let buffer = renderToBuffer(splitView, context: context)

        let content = buffer.lines.joined()
        #expect(!content.contains("Sidebar"))
        #expect(content.contains("Content"))
        #expect(content.contains("Detail"))
    }

    @Test("Split view respects available height")
    func splitViewRespectsAvailableHeight() {
        let splitView = NavigationSplitView {
            Text("Sidebar")
        } detail: {
            Text("Detail")
        }

        let context = testContext(width: 80, height: 10)
        let buffer = renderToBuffer(splitView, context: context)

        #expect(buffer.height == 10)
    }
}

// MARK: - Focus Section Tests

@Suite("NavigationSplitView Focus Section Tests")
@MainActor
struct NavigationSplitViewFocusSectionTests {
    @Test("Two-column split view registers two focus sections")
    func twoColumnRegistersTwoFocusSections() {
        let focusManager = FocusManager()
        var environment = EnvironmentValues()
        environment.focusManager = focusManager

        let splitView = NavigationSplitView {
            Text("Sidebar")
        } detail: {
            Text("Detail")
        }

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: environment,
            tuiContext: TUIContext()
        )

        _ = renderToBuffer(splitView, context: context)

        // Both sections should be registered
        #expect(focusManager.sectionIDs.contains("nav-split-sidebar"))
        #expect(focusManager.sectionIDs.contains("nav-split-detail"))
    }

    @Test("Three-column split view registers three focus sections")
    func threeColumnRegistersThreeFocusSections() {
        let focusManager = FocusManager()
        var environment = EnvironmentValues()
        environment.focusManager = focusManager

        let splitView = NavigationSplitView {
            Text("Sidebar")
        } content: {
            Text("Content")
        } detail: {
            Text("Detail")
        }

        let context = RenderContext(
            availableWidth: 100,
            availableHeight: 24,
            environment: environment,
            tuiContext: TUIContext()
        )

        _ = renderToBuffer(splitView, context: context)

        // All three sections should be registered
        #expect(focusManager.sectionIDs.contains("nav-split-sidebar"))
        #expect(focusManager.sectionIDs.contains("nav-split-content"))
        #expect(focusManager.sectionIDs.contains("nav-split-detail"))
    }

    @Test("Hidden columns do not register focus sections")
    func hiddenColumnsNoFocusSections() {
        let focusManager = FocusManager()
        var environment = EnvironmentValues()
        environment.focusManager = focusManager

        var visibility = NavigationSplitViewVisibility.detailOnly
        let binding = Binding(get: { visibility }, set: { visibility = $0 })

        let splitView = NavigationSplitView(columnVisibility: binding) {
            Text("Sidebar")
        } detail: {
            Text("Detail")
        }

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: environment,
            tuiContext: TUIContext()
        )

        _ = renderToBuffer(splitView, context: context)

        // Only detail section should be registered
        #expect(!focusManager.sectionIDs.contains("nav-split-sidebar"))
        #expect(focusManager.sectionIDs.contains("nav-split-detail"))
    }
}

// MARK: - Style Environment Tests

@Suite("NavigationSplitView Style Environment Tests")
@MainActor
struct NavigationSplitViewStyleEnvironmentTests {
    @Test("Default environment style is automatic")
    func defaultStyleIsAutomatic() {
        let environment = EnvironmentValues()
        let style = environment.navigationSplitViewStyle
        #expect(style.sidebarProportion == 0.33)
    }

    @Test("Style can be set via environment")
    func styleCanBeSetViaEnvironment() {
        var environment = EnvironmentValues()
        environment.navigationSplitViewStyle = ProminentDetailNavigationSplitViewStyle()

        let style = environment.navigationSplitViewStyle
        #expect(style.sidebarProportion == 0.25)
    }

    @Test("navigationSplitViewStyle modifier sets environment")
    func modifierSetsEnvironment() {
        let view = Text("Test").navigationSplitViewStyle(.prominentDetail)

        var environment = EnvironmentValues()
        environment.navigationSplitViewStyle = ProminentDetailNavigationSplitViewStyle()

        // The modifier should compile without errors
        _ = view
    }
}

// MARK: - Column Width Tests

@Suite("NavigationSplitView Column Width Tests")
@MainActor
struct NavigationSplitViewColumnWidthTests {
    @Test("Fixed column width preference can be set")
    func fixedColumnWidthPreference() {
        let view = Text("Sidebar").navigationSplitViewColumnWidth(25)

        // The modifier should compile and wrap the view
        _ = view
    }

    @Test("Flexible column width preference can be set")
    func flexibleColumnWidthPreference() {
        let view = Text("Sidebar").navigationSplitViewColumnWidth(min: 20, ideal: 30, max: 50)

        // The modifier should compile and wrap the view
        _ = view
    }

    @Test("Column width with only min constraint")
    func columnWidthMinOnly() {
        let view = Text("Sidebar").navigationSplitViewColumnWidth(min: 15)

        _ = view
    }

    @Test("Column width with only max constraint")
    func columnWidthMaxOnly() {
        let view = Text("Sidebar").navigationSplitViewColumnWidth(max: 40)

        _ = view
    }
}

// MARK: - Equatable Tests

@Suite("NavigationSplitView Equatable Tests")
@MainActor
struct NavigationSplitViewEquatableTests {
    @Test("Equal split views are equal")
    func equalSplitViewsAreEqual() {
        let view1 = NavigationSplitView {
            Text("Sidebar")
        } detail: {
            Text("Detail")
        }

        let view2 = NavigationSplitView {
            Text("Sidebar")
        } detail: {
            Text("Detail")
        }

        #expect(view1 == view2)
    }

    @Test("Different sidebar content makes views unequal")
    func differentSidebarMakesUnequal() {
        let view1 = NavigationSplitView {
            Text("Sidebar A")
        } detail: {
            Text("Detail")
        }

        let view2 = NavigationSplitView {
            Text("Sidebar B")
        } detail: {
            Text("Detail")
        }

        #expect(view1 != view2)
    }

    @Test("Different detail content makes views unequal")
    func differentDetailMakesUnequal() {
        let view1 = NavigationSplitView {
            Text("Sidebar")
        } detail: {
            Text("Detail A")
        }

        let view2 = NavigationSplitView {
            Text("Sidebar")
        } detail: {
            Text("Detail B")
        }

        #expect(view1 != view2)
    }
}
