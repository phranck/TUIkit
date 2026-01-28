//
//  ContentView.swift
//  SwiftTUIExample
//
//  The main content view that routes between demo pages.
//

import SwiftTUI

// MARK: - Content View (Page Router)

/// The main content view that switches between pages.
///
/// This view acts as a router, displaying the appropriate demo page
/// based on the current state. It uses the `.statusBarItems()` modifier
/// to declaratively set context-sensitive status bar items.
struct ContentView: TView {
    var body: some TView {
        let state = ExampleAppState.shared

        // Show current page based on state
        pageContent(for: state.currentPage)
            .onKeyPress { event in
                switch event.key {
                case .escape:
                    // ESC goes back to menu (or exits if already on menu)
                    if state.currentPage != .menu {
                        state.currentPage = .menu
                        return true  // Consumed
                    }
                    return false  // Let default handler exit the app

                default:
                    return false  // Let other handlers process
                }
            }
    }

    @TViewBuilder
    private func pageContent(for page: DemoPage) -> some TView {
        switch page {
        case .menu:
            MainMenuPage()
                .statusBarItems {
                    TStatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "nav")
                    TStatusBarItem(shortcut: Shortcut.enter, label: "select", key: .enter)
                    TStatusBarItem(shortcut: Shortcut.range("1", "6"), label: "jump")
                    TStatusBarItem(shortcut: Shortcut.quit, label: "quit")
                }
        case .textStyles:
            TextStylesPage()
                .statusBarItems(subPageItems)
        case .colors:
            ColorsPage()
                .statusBarItems(subPageItems)
        case .containers:
            ContainersPage()
                .statusBarItems(subPageItems)
        case .overlays:
            OverlaysPage()
                .statusBarItems(subPageItems)
        case .layout:
            LayoutPage()
                .statusBarItems(subPageItems)
        case .buttons:
            ButtonsPage()
                .statusBarItems(subPageItems)
        }
    }

    /// Common status bar items for sub-pages.
    private var subPageItems: [any TStatusBarItemProtocol] {
        [
            TStatusBarItem(shortcut: Shortcut.escape, label: "back") {
                ExampleAppState.shared.currentPage = .menu
            },
            TStatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "scroll"),
            TStatusBarItem(shortcut: Shortcut.quit, label: "quit")
        ]
    }
}
