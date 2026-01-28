//
//  ContentView.swift
//  TUIKitExample
//
//  The main content view that routes between demo pages.
//

import TUIKit

// MARK: - Content View (Page Router)

/// The main content view that switches between pages.
///
/// This view acts as a router, displaying the appropriate demo page
/// based on the current state. It uses the `.statusBarItems()` modifier
/// to declaratively set context-sensitive status bar items.
struct ContentView: View {
    var body: some View {
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

    @ViewBuilder
    private func pageContent(for page: DemoPage) -> some View {
        switch page {
        case .menu:
            MainMenuPage()
                .statusBarItems {
                    StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "nav")
                    StatusBarItem(shortcut: Shortcut.enter, label: "select", key: .enter)
                    StatusBarItem(shortcut: Shortcut.range("1", "6"), label: "jump")
                    StatusBarItem(shortcut: Shortcut.quit, label: "quit")
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
    private var subPageItems: [any StatusBarItemProtocol] {
        [
            StatusBarItem(shortcut: Shortcut.escape, label: "back") {
                ExampleAppState.shared.currentPage = .menu
            },
            StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "scroll"),
            StatusBarItem(shortcut: Shortcut.quit, label: "quit")
        ]
    }
}
