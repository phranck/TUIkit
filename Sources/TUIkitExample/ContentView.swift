//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ContentView.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

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
    case spinners
}

// MARK: - Content View (Page Router)

/// The main content view that switches between pages.
///
/// This view acts as a router, displaying the appropriate demo page
/// based on the current state. It uses `@State` for all reactive
/// properties — exactly like SwiftUI.
struct ContentView: View {
    @State var currentPage: DemoPage = .menu
    @State var menuSelection: Int = 0

    var body: some View {
        // Capture bindings for use in closures
        let pageSetter = $currentPage

        // Show current page based on state
        // Note: Background color is set by AppRunner using theme.background
        pageContent(for: currentPage, pageSetter: pageSetter)
            .onKeyPress { event in
                switch event.key {
                case .escape:
                    // ESC goes back to menu (or exits if already on menu)
                    if currentPage != .menu {
                        pageSetter.wrappedValue = .menu
                        return true  // Consumed
                    }
                    return false  // Let default handler exit the app

                default:
                    return false  // Let other handlers process
                }
            }
    }

    @ViewBuilder
    private func pageContent(for page: DemoPage, pageSetter: Binding<DemoPage>) -> some View {
        switch page {
        case .menu:
            MainMenuPage(currentPage: $currentPage, menuSelection: $menuSelection)
                .statusBarItems {
                    StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "nav")
                    StatusBarItem(shortcut: Shortcut.enter, label: "select", key: .enter)
                    StatusBarItem(shortcut: Shortcut.range("1", "8"), label: "jump")
                }
        case .textStyles:
            TextStylesPage()
                .statusBarItems(subPageItems(pageSetter: pageSetter))
        case .colors:
            ColorsPage()
                .statusBarItems(subPageItems(pageSetter: pageSetter))
        case .containers:
            ContainersPage()
                .statusBarItems(subPageItems(pageSetter: pageSetter))
        case .overlays:
            OverlaysPage(onBack: { pageSetter.wrappedValue = .menu })
        case .layout:
            LayoutPage()
                .statusBarItems(subPageItems(pageSetter: pageSetter))
        case .buttons:
            ButtonsPage()
                .statusBarItems(subPageItems(pageSetter: pageSetter))
        case .spinners:
            SpinnersPage()
                .statusBarItems(subPageItems(pageSetter: pageSetter))
        }
    }

    /// Common status bar items for sub-pages.
    private func subPageItems(pageSetter: Binding<DemoPage>) -> [any StatusBarItemProtocol] {
        [
            StatusBarItem(shortcut: Shortcut.escape, label: "back") { [pageSetter] in
                pageSetter.wrappedValue = .menu
            },
            StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "scroll"),
        ]
    }
}
