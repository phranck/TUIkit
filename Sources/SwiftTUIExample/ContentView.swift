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
/// based on the current state. It also handles the ESC key to
/// navigate back to the main menu.
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
        case .textStyles:
            TextStylesPage()
        case .colors:
            ColorsPage()
        case .containers:
            ContainersPage()
        case .overlays:
            OverlaysPage()
        case .layout:
            LayoutPage()
        case .buttons:
            ButtonsPage()
        }
    }
}
