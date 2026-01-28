//
//  AppState.swift
//  SwiftTUIExample
//
//  Global state management for the example app.
//

import SwiftTUI

// MARK: - Demo Page Enum

/// The available demo pages in the example app.
enum DemoPage: Int, CaseIterable {
    case menu = 0
    case textStyles = 1
    case colors = 2
    case containers = 3
    case overlays = 4
    case layout = 5
    case buttons = 6
}

// MARK: - App State

/// Global state for the example app.
///
/// This class manages the current page and menu selection.
/// Changes trigger automatic re-renders via `AppState`.
final class ExampleAppState: @unchecked Sendable {
    static let shared = ExampleAppState()

    /// The current page being displayed.
    var currentPage: DemoPage = .menu {
        didSet {
            updateStatusBar()
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

    private init() {
        // Set up initial status bar
        updateStatusBar()
    }

    /// Updates the status bar based on the current page.
    ///
    /// The status bar shows context-sensitive shortcuts:
    /// - Main menu: navigation, selection, and quit
    /// - Sub-pages: back navigation and quit
    func updateStatusBar() {
        switch currentPage {
        case .menu:
            // Main menu: navigation + quit
            StatusBarManager.shared.setGlobalItems([
                TStatusBarItem(shortcut: "↑↓", label: "nav"),
                TStatusBarItem(shortcut: "↵", label: "select", key: .enter),
                TStatusBarItem(shortcut: "1-6", label: "jump"),
                TStatusBarItem(shortcut: "q", label: "quit")
            ])

        default:
            // Sub-pages: back + quit
            StatusBarManager.shared.setGlobalItems([
                TStatusBarItem(shortcut: "⎋", label: "back") { [weak self] in
                    self?.currentPage = .menu
                },
                TStatusBarItem(shortcut: "↑↓", label: "scroll"),
                TStatusBarItem(shortcut: "q", label: "quit")
            ])
        }
    }
}
