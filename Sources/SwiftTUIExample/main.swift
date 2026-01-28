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
enum DemoPage: String, CaseIterable {
    case menu = "Main Menu"
    case textStyles = "Text Styles"
    case colors = "Colors"
    case containers = "Containers"
    case overlays = "Overlays"
    case layout = "Layout"
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
                    Text("[B] Back to Menu")
                        .dim()
                    Text("  ")
                }
                Text("[Q] Quit")
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

// MARK: - Main Menu Page

struct MainMenuPage: TView {
    var body: some TView {
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
                        MenuItem(label: "Quit", shortcut: "q")
                    ],
                    selectedIndex: 0,
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

            DemoSection("Hex Colors") {
                HStack(spacing: 2) {
                    Text("#FF6B6B").foregroundColor(.hex(0xFF6B6B))
                    Text("#4ECDC4").foregroundColor(.hex(0x4ECDC4))
                    Text("#45B7D1").foregroundColor(.hex(0x45B7D1))
                    Text("#96CEB4").foregroundColor(.hex(0x96CEB4))
                }
            }

            DemoSection("Semantic Colors") {
                HStack(spacing: 2) {
                    Text("Primary").foregroundColor(.primary)
                    Text("Secondary").foregroundColor(.secondary)
                    Text("Accent").foregroundColor(.accent)
                }
                HStack(spacing: 2) {
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
                        Text("and border")
                    }
                }

                // Box example
                VStack(alignment: .leading) {
                    Text("Box").bold().foregroundColor(.yellow)
                    Box(.doubleLine, color: .green) {
                        Text("Simple Box")
                        Text("Double line border")
                    }
                }
            }

            HStack(spacing: 2) {
                // Panel example
                VStack(alignment: .leading) {
                    Text("Panel").bold().foregroundColor(.yellow)
                    Panel("Settings", borderStyle: .line, titleColor: .magenta) {
                        Text("Title in border")
                        Text("Great for sections")
                    }
                }

                // Nested containers
                VStack(alignment: .leading) {
                    Text("Nested").bold().foregroundColor(.yellow)
                    Box(.rounded, color: .brightBlack) {
                        Card(borderColor: .cyan) {
                            Text("Box > Card")
                        }
                    }
                }
            }

            DemoSection("Border Styles") {
                HStack(spacing: 1) {
                    Box(.line) { Text("line") }
                    Box(.rounded) { Text("rounded") }
                    Box(.doubleLine) { Text("double") }
                    Box(.heavy) { Text("heavy") }
                }
                HStack(spacing: 1) {
                    Box(.dashed) { Text("dashed") }
                    Box(.dotted) { Text("dotted") }
                    Box(.ascii) { Text("ascii") }
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
                Text("• Character-level compositing in FrameBuffer")
            }

            DemoSection("Alert Presets") {
                HStack(spacing: 2) {
                    VStack {
                        Text("Warning").foregroundColor(.yellow)
                        Text("Yellow border")
                    }
                    VStack {
                        Text("Error").foregroundColor(.red)
                        Text("Red border")
                    }
                    VStack {
                        Text("Info").foregroundColor(.cyan)
                        Text("Cyan border")
                    }
                    VStack {
                        Text("Success").foregroundColor(.green)
                        Text("Green border")
                    }
                }
            }

            DemoSection("Dialog View") {
                Text("Dialog is a flexible modal container")
                Text("with a title bar (Panel-based)")
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
///
/// This demonstrates the Menu view and multiple demo pages.
/// In a real app with state management, you would switch pages
/// based on user input.
struct ExampleApp: TApp {
    var body: some TScene {
        WindowGroup {
            // Show the main menu page
            // In a real app, you'd switch between pages based on state
            MainMenuPage()
        }
    }
}

// Run the app
ExampleApp.main()
