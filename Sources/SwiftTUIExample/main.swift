//
//  main.swift
//  SwiftTUIExample
//
//  A comprehensive example app demonstrating SwiftTUI capabilities.
//  Features a main menu with multiple demo pages.
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
}

// MARK: - App State

/// Global state for the example app.
/// Using a simple class with manual AppState notification.
final class ExampleAppState: @unchecked Sendable {
    static let shared = ExampleAppState()

    /// The current page being displayed.
    var currentPage: DemoPage = .menu {
        didSet { AppState.shared.setNeedsRender() }
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

// MARK: - Shared Components

/// A styled header with title on the left and version on the right.
struct HeaderView: TView {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some TView {
        VStack {
            HStack {
                Text(title)
                    .bold()
                    .foregroundColor(.cyan)
                Spacer()
                Text("SwiftTUI v\(swiftTUIVersion)")
                    .dim()
            }
            if let sub = subtitle {
                Text(sub)
                    .dim()
                    .italic()
            }
            Divider(character: "═")
        }
    }
}

/// A footer with navigation hints.
struct FooterView: TView {
    let showBackHint: Bool

    var body: some TView {
        VStack {
            Divider(character: "─")
            HStack {
                if showBackHint {
                    Text("[ESC] Back")
                        .dim()
                    Text("  ")
                }
                Text("[↑↓] Navigate  [Enter] Select  [Q] Quit")
                    .dim()
                Spacer()
                Text("SwiftTUI")
                    .dim()
                    .italic()
            }
        }
    }
}

/// A section with a title and content.
struct DemoSection<Content: TView>: TView {
    let title: String
    let content: Content

    init(_ title: String, @TViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some TView {
        VStack(alignment: .leading) {
            Text(title)
                .bold()
                .underline()
                .foregroundColor(.yellow)
            content
        }
    }
}

// MARK: - Content View (Page Router)

/// The main content view that switches between pages.
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
        }
    }
}

// MARK: - Main Menu Page

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
                        MenuItem(label: "Layout System", shortcut: "5")
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

            FooterView(showBackHint: false)
        }
    }

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

// MARK: - Text Styles Demo Page

struct TextStylesPage: TView {
    var body: some TView {
        VStack(spacing: 1) {
            HeaderView(title: "Text Styles Demo")

            DemoSection("Basic Styles") {
                Text("Normal text - no styling applied")
                Text("Bold text").bold()
                Text("Italic text").italic()
                Text("Underlined text").underline()
                Text("Strikethrough text").strikethrough()
                Text("Dimmed text").dim()
            }

            DemoSection("Combined Styles") {
                Text("Bold + Italic").bold().italic()
                Text("Bold + Underline").bold().underline()
                Text("Bold + Color").bold().foregroundColor(.cyan)
                Text("Italic + Dim").italic().dim()
                Text("All combined").bold().italic().underline().foregroundColor(.magenta)
            }

            DemoSection("Special Effects") {
                Text("Blinking text (if terminal supports)").blink()
                Text("Inverted colors").inverted()
            }

            Spacer()
            FooterView(showBackHint: true)
        }
    }
}

// MARK: - Colors Demo Page

struct ColorsPage: TView {
    var body: some TView {
        VStack(spacing: 1) {
            HeaderView(title: "Colors Demo")

            DemoSection("Standard ANSI Colors") {
                HStack(spacing: 2) {
                    Text("Black").foregroundColor(.black).background(.white)
                    Text("Red").foregroundColor(.red)
                    Text("Green").foregroundColor(.green)
                    Text("Yellow").foregroundColor(.yellow)
                }
                HStack(spacing: 2) {
                    Text("Blue").foregroundColor(.blue)
                    Text("Magenta").foregroundColor(.magenta)
                    Text("Cyan").foregroundColor(.cyan)
                    Text("White").foregroundColor(.white)
                }
            }

            DemoSection("Bright Colors") {
                HStack(spacing: 2) {
                    Text("Bright Red").foregroundColor(.brightRed)
                    Text("Bright Green").foregroundColor(.brightGreen)
                    Text("Bright Yellow").foregroundColor(.brightYellow)
                    Text("Bright Blue").foregroundColor(.brightBlue)
                }
            }

            DemoSection("RGB Colors (24-bit)") {
                HStack(spacing: 2) {
                    Text("Orange").foregroundColor(.rgb(255, 128, 0))
                    Text("Pink").foregroundColor(.rgb(255, 105, 180))
                    Text("Teal").foregroundColor(.rgb(0, 128, 128))
                    Text("Purple").foregroundColor(.rgb(128, 0, 128))
                }
            }

            DemoSection("Semantic Colors") {
                HStack(spacing: 2) {
                    Text("Primary").foregroundColor(.primary)
                    Text("Success").foregroundColor(.success)
                    Text("Warning").foregroundColor(.warning)
                    Text("Error").foregroundColor(.error)
                }
            }

            Spacer()
            FooterView(showBackHint: true)
        }
    }
}

// MARK: - Containers Demo Page

struct ContainersPage: TView {
    var body: some TView {
        VStack(spacing: 1) {
            HeaderView(title: "Container Views Demo")

            HStack(spacing: 2) {
                // Card example
                VStack(alignment: .leading) {
                    Text("Card").bold().foregroundColor(.yellow)
                    Card(borderStyle: .rounded, borderColor: .cyan) {
                        Text("A Card view")
                        Text("with padding").dim()
                    }
                }

                // Box example
                VStack(alignment: .leading) {
                    Text("Box").bold().foregroundColor(.yellow)
                    Box(.doubleLine, color: .green) {
                        Text("Simple Box")
                    }
                }

                // Panel example
                VStack(alignment: .leading) {
                    Text("Panel").bold().foregroundColor(.yellow)
                    Panel("Info", borderStyle: .line, titleColor: .magenta) {
                        Text("Title in border")
                    }
                }
            }

            DemoSection("Border Styles") {
                HStack(spacing: 1) {
                    Box(.line) { Text("line") }
                    Box(.rounded) { Text("rounded") }
                    Box(.doubleLine) { Text("double") }
                    Box(.heavy) { Text("heavy") }
                    Box(.block) { Text("block") }
                }
            }

            Spacer()
            FooterView(showBackHint: true)
        }
    }
}

// MARK: - Overlays Demo Page

struct OverlaysPage: TView {
    var body: some TView {
        // Background content with modal overlay
        backgroundContent
            .modal {
                Alert(
                    title: "Modal Alert",
                    message: "This alert overlays dimmed content!",
                    borderStyle: .rounded,
                    borderColor: .yellow,
                    titleColor: .yellow
                ) {
                    HStack {
                        Text("[OK]").bold().foregroundColor(.green)
                        Spacer()
                        Text("[Cancel]").foregroundColor(.red)
                    }
                }
            }
    }

    var backgroundContent: some TView {
        VStack(spacing: 1) {
            HeaderView(title: "Overlays & Modals Demo")

            DemoSection("Overlay System Features") {
                Text("• .overlay() modifier - layer content on top")
                Text("• .dimmed() modifier - reduce visual emphasis")
                Text("• .modal() helper - combines dimmed + centered overlay")
            }

            DemoSection("This page demonstrates a modal overlay") {
                Text("The content behind is dimmed automatically")
                Text("Press [B] to go back to the menu")
            }

            Spacer()
            FooterView(showBackHint: true)
        }
    }
}

// MARK: - Layout Demo Page

struct LayoutPage: TView {
    var body: some TView {
        VStack(spacing: 1) {
            HeaderView(title: "Layout System Demo")

            DemoSection("VStack (Vertical)") {
                Box(.rounded, color: .brightBlack) {
                    VStack(spacing: 0) {
                        Text("Item 1")
                        Text("Item 2")
                        Text("Item 3")
                    }
                }
            }

            DemoSection("HStack (Horizontal)") {
                Box(.rounded, color: .brightBlack) {
                    HStack(spacing: 2) {
                        Text("Left")
                        Text("Center")
                        Text("Right")
                    }
                }
            }

            DemoSection("Spacer") {
                Box(.rounded, color: .brightBlack) {
                    HStack {
                        Text("Start")
                        Spacer()
                        Text("End")
                    }
                }
            }

            DemoSection("Padding & Frame") {
                HStack(spacing: 2) {
                    VStack {
                        Text(".padding()").dim()
                        Text("Padded")
                            .padding(EdgeInsets(all: 1))
                            .border(.line)
                    }
                    VStack {
                        Text(".frame()").dim()
                        Text("Framed")
                            .frame(width: 15, alignment: .center)
                            .border(.line)
                    }
                }
            }

            Spacer()
            FooterView(showBackHint: true)
        }
    }
}

// MARK: - Main App

/// The main example application.
struct ExampleApp: TApp {
    var body: some TScene {
        WindowGroup {
            ContentView()
        }
    }
}

// Run the app
ExampleApp.main()
