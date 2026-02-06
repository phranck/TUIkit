//  🖥️ TUIKit — Terminal UI Kit for Swift
//  MainMenuPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// A small feature highlight box with a bold title and subtitle.
///
/// Used on the main menu to showcase key framework properties.
/// Stateless and palette-driven — wrapped in `.equatable()` for
/// subtree memoization during Spinner/Pulse animation frames.
struct FeatureBox: View, Equatable {
    /// The bold headline text.
    let title: String

    /// The secondary description text.
    let subtitle: String

    init(_ title: String, _ subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack {
            Text(title)
                .bold()
                .foregroundColor(.palette.accent)
            Text(subtitle)
                .foregroundColor(.palette.foregroundSecondary)
        }
        .padding(EdgeInsets(horizontal: 2, vertical: 1))
        .border(color: .palette.border)
    }
}

/// The main menu page.
///
/// Displays a centered menu with all available demos and
/// feature highlight boxes at the bottom.
struct MainMenuPage: View {
    @Binding var currentPage: DemoPage
    @Binding var menuSelection: Int

    var body: some View {
        VStack(spacing: 1) {
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
                          MenuItem(label: "Buttons & Focus", shortcut: "6"),
                          MenuItem(label: "Toggles & Checkboxes", shortcut: "7"),
                          MenuItem(label: "Radio Buttons", shortcut: "8"),
                          MenuItem(label: "Scrollable List", shortcut: "9"),
                          MenuItem(label: "Spinners", shortcut: "0"),
                      ],
                     selection: $menuSelection,
                     onSelect: { index in
                         // Navigate to the selected page
                         if let page = DemoPage(rawValue: index + 1) {
                             currentPage = page
                         }
                     },
                     selectedColor: .palette.accent,
                     // borderStyle uses appearance default
                     borderColor: .palette.border
                 )
                Spacer()
            }

            Spacer(minLength: 1)

            // Feature highlights (centered)
            HStack {
                Spacer()
                HStack(spacing: 3) {
                    FeatureBox("Pure Swift", "No ncurses").equatable()
                    FeatureBox("Declarative", "SwiftUI-like").equatable()
                    FeatureBox("Composable", "View protocol").equatable()
                }
                Spacer()
            }

            Spacer()
        }
        .appHeader {
            VStack {
                HStack {
                    Text("TUIkit Example App").bold().foregroundColor(.palette.accent)
                    Spacer()
                    Text("TUIkit v\(tuiKitVersion)").foregroundColor(.palette.foregroundTertiary)
                }
                Text("A SwiftUI-like framework for Terminal User Interfaces")
                    .foregroundColor(.palette.foregroundSecondary)
                    .italic()
            }
        }
    }
}
