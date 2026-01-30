//
//  AppState.swift
//  TUIKitExample
//
//  Global state management for the example app.
//

import TUIKit

// MARK: - Demo Page Enum

/// The available demo pages in the example app.
enum DemoPage: Int, CaseIterable {
    case menu
    case textStyles
    case colors
    case containers
    case overlays
    case layout
    case buttons
}

// MARK: - App State

/// Global state for the example app.
///
/// This class manages the current page and menu selection.
/// Changes trigger automatic re-renders via `AppState`.
///
/// Status bar items are now managed declaratively via the
/// `.statusBarItems()` modifier in `ContentView`.
final class ExampleAppState: @unchecked Sendable {
    static let shared = ExampleAppState()

    /// The current page being displayed.
    var currentPage: DemoPage = .menu {
        didSet {
            AppState.shared.setNeedsRender()
        }
    }

    /// The selected menu index.
    var menuSelection: Int = 0 {
        didSet { AppState.shared.setNeedsRender() }
    }

    /// Binding for menu selection.
    var menuSelectionBinding: Binding<Int> {
        Binding(
            get: { self.menuSelection },
            set: { self.menuSelection = $0 }
        )
    }

    private init() {}
}
