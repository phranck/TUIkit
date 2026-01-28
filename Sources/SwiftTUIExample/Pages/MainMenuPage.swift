//
//  MainMenuPage.swift
//  SwiftTUIExample
//
//  The main menu page with navigation to all demos.
//

import SwiftTUI

/// The main menu page.
///
/// Displays a centered menu with all available demos and
/// feature highlight boxes at the bottom.
struct MainMenuPage: TView {
    var body: some TView {
        let state = ExampleAppState.shared

        VStack(spacing: 1) {
            HeaderView(
                title: "SwiftTUI Example App",
                subtitle: "A SwiftUI-like framework for Terminal User Interfaces"
            )

            Spacer(minLength: 1)

            HStack {
                Spacer()
                Menu(
                    title: "Select a Demo",
                    items: [
                        MenuItem(label: "Text Styles", shortcut: "1"),
                        MenuItem(label: "Colors", shortcut: "2"),
                        MenuItem(label: "Container Views", shortcut: "3"),
                        MenuItem(label: "Overlays & Modals", shortcut: "4"),
                        MenuItem(label: "Layout System", shortcut: "5"),
                        MenuItem(label: "Buttons & Focus", shortcut: "6")
                    ],
                    selection: state.menuSelectionBinding,
                    onSelect: { index in
                        // Navigate to the selected page
                        if let page = DemoPage(rawValue: index + 1) {
                            state.currentPage = page
                        }
                    },
                    selectedColor: .cyan,
                    borderStyle: .rounded,
                    borderColor: .brightBlack
                )
                Spacer()
            }

            Spacer(minLength: 1)

            // Feature highlights (centered)
            HStack {
                Spacer()
                HStack(spacing: 3) {
                    featureBox("Pure Swift", "No ncurses")
                    featureBox("Declarative", "SwiftUI-like")
                    featureBox("Composable", "View protocol")
                }
                Spacer()
            }

            Spacer()
        }
    }

    /// Creates a small feature highlight box.
    private func featureBox(_ title: String, _ subtitle: String) -> some TView {
        VStack {
            Text(title)
                .bold()
                .foregroundColor(.green)
            Text(subtitle)
                .dim()
        }
        .padding(EdgeInsets(horizontal: 2, vertical: 1))
        .border(.rounded, color: .brightBlack)
    }
}
