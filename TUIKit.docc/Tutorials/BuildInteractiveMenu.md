# Building an Interactive Menu

Create a navigation menu with keyboard shortcuts and status bar hints.

@Intro(title: "Build an Interactive Menu App") {
    Learn how to create a functional menu system with keyboard navigation,
    selection handling, and status bar integration.

    You'll build a simple settings menu that demonstrates focus management,
    keyboard events, and status bar items.
}

## Overview

In this tutorial, you'll create a menu-driven application featuring:

- `Menu` component for selection
- Keyboard shortcut handling
- Status bar with hints
- Page navigation patterns

@Section(title: "Create the Menu Component") {
    @ContentAndMedia {
        Start with a basic menu that displays options and tracks selection.
    }

    @Steps {
        @Step {
            Create your app with a `Menu`:

            ```swift
            import TUIKit

            @main
            struct MenuApp: App {
                @State private var selectedOption: String = "home"

                var body: some Scene {
                    WindowGroup {
                        VStack(spacing: 2) {
                            Text("Main Menu")
                                .bold()
                                .foregroundColor(.theme.accent)

                            Spacer()

                            Menu(
                                items: [
                                    MenuItem("📄 View Profile", id: "profile"),
                                    MenuItem("⚙️  Settings", id: "settings"),
                                    MenuItem("💾 Save Data", id: "save"),
                                    MenuItem("❌ Exit", id: "exit")
                                ],
                                selection: $selectedOption
                            )

                            Spacer()

                            Text("Selected: \(selectedOption)")
                                .foregroundColor(.theme.foregroundSecondary)
                        }
                        .padding()
                    }
                }
            }
            ```

            - `Menu` creates an interactive selectable list
            - `$selectedOption` creates a two-way binding
            - Use Tab/Arrow keys to navigate
            - Press Enter to confirm selection
        }

        @Step {
            Run the app:

            ```bash
            swift run
            ```

            Test navigating with Tab, arrow keys, and Enter.
            The "Selected" text updates as you navigate.
        }
    }
}

@Section(title: "Add Page Navigation") {
    @ContentAndMedia {
        Create different pages that show based on menu selection.
    }

    @Steps {
        @Step {
            Add conditional pages:

            ```swift
            @main
            struct MenuApp: App {
                @State private var selectedOption: String = "home"

                var body: some Scene {
                    WindowGroup {
                        if selectedOption == "exit" {
                            VStack {
                                Text("Exiting...")
                            }
                        } else {
                            VStack(spacing: 2) {
                                Text("Main Menu")
                                    .bold()
                                    .foregroundColor(.theme.accent)

                                Spacer()

                                Menu(
                                    items: [
                                        MenuItem("📄 View Profile", id: "profile"),
                                        MenuItem("⚙️  Settings", id: "settings"),
                                        MenuItem("💾 Save Data", id: "save"),
                                        MenuItem("❌ Exit", id: "exit")
                                    ],
                                    selection: $selectedOption
                                )

                                Spacer()

                                currentPageContent
                            }
                            .padding()
                        }
                    }
                }

                @ViewBuilder
                var currentPageContent: some View {
                    switch selectedOption {
                    case "profile":
                        VStack(spacing: 1) {
                            Text("📄 Profile Information").bold()
                            Text("Name: John Doe")
                            Text("Role: Developer")
                        }
                    case "settings":
                        VStack(spacing: 1) {
                            Text("⚙️  Application Settings").bold()
                            Text("Theme: Green")
                            Text("Language: English")
                        }
                    case "save":
                        Text("✓ Data saved successfully!")
                            .foregroundColor(.theme.success)
                    default:
                        Text("Select an option above")
                    }
                }
            }
            ```

            The `currentPageContent` computed property shows different content
            based on the selected menu item.
        }

        @Step {
            Run and test navigation:

            ```bash
            swift run
            ```

            Navigate to each menu item and see the page content change.
        }
    }
}

@Section(title: "Add Status Bar Hints") {
    @ContentAndMedia {
        Add a status bar at the bottom with helpful keyboard hints.
    }

    @Steps {
        @Step {
            Add status bar items:

            ```swift
            @main
            struct MenuApp: App {
                @State private var selectedOption: String = "home"

                var body: some Scene {
                    WindowGroup {
                        if selectedOption == "exit" {
                            VStack {
                                Text("Exiting...")
                            }
                        } else {
                            VStack(spacing: 2) {
                                Text("Main Menu")
                                    .bold()
                                    .foregroundColor(.theme.accent)

                                Spacer()

                                Menu(
                                    items: [
                                        MenuItem("📄 View Profile", id: "profile"),
                                        MenuItem("⚙️  Settings", id: "settings"),
                                        MenuItem("💾 Save Data", id: "save"),
                                        MenuItem("❌ Exit", id: "exit")
                                    ],
                                    selection: $selectedOption
                                )

                                Spacer()

                                currentPageContent
                            }
                            .padding()
                        }
                        .statusBarItems {
                            StatusBarItem(
                                label: "Select",
                                shortcut: Shortcut.enter,
                                action: { }
                            )

                            StatusBarItem(
                                label: "Theme",
                                shortcut: Shortcut.letter("t"),
                                action: { }
                            )

                            StatusBarItem(
                                label: "Help",
                                shortcut: Shortcut.letter("?"),
                                action: { }
                            )

                            StatusBarItem(
                                label: "Quit",
                                shortcut: Shortcut.letter("q"),
                                action: { }
                            )
                        }
                    }
                }

                @ViewBuilder
                var currentPageContent: some View {
                    switch selectedOption {
                    case "profile":
                        VStack(spacing: 1) {
                            Text("📄 Profile Information").bold()
                            Text("Name: John Doe")
                            Text("Role: Developer")
                        }
                    case "settings":
                        VStack(spacing: 1) {
                            Text("⚙️  Application Settings").bold()
                            Text("Theme: Green")
                            Text("Language: English")
                        }
                    case "save":
                        Text("✓ Data saved successfully!")
                            .foregroundColor(.theme.success)
                    default:
                        Text("Select an option above")
                    }
                }
            }
            ```

            `statusBarItems` adds a bottom status bar with keyboard shortcuts.
        }

        @Step {
            Run the app:

            ```bash
            swift run
            ```

            The status bar appears at the bottom showing available shortcuts.
        }
    }
}

@Section(title: "Add Keyboard Shortcuts") {
    @ContentAndMedia {
        Handle custom keyboard shortcuts to navigate directly to menu items.
    }

    @Steps {
        @Step {
            Add keyboard event handling:

            ```swift
            .onKeyPress { event in
                switch event.key {
                case .character("1"):
                    selectedOption = "profile"
                    return true
                case .character("2"):
                    selectedOption = "settings"
                    return true
                case .character("3"):
                    selectedOption = "save"
                    return true
                case .character("e"):
                    selectedOption = "exit"
                    return true
                default:
                    return false
                }
            }
            ```

            Add this modifier to your main `VStack`. Now users can:
            - Press `1` to go to Profile
            - Press `2` to go to Settings
            - Press `3` to Save
            - Press `e` to Exit
        }

        @Step {
            Update the status bar to show these shortcuts:

            ```swift
            .statusBarItems {
                StatusBarItem(
                    label: "Profile",
                    shortcut: Shortcut.digit("1"),
                    action: { }
                )

                StatusBarItem(
                    label: "Settings",
                    shortcut: Shortcut.digit("2"),
                    action: { }
                )

                StatusBarItem(
                    label: "Save",
                    shortcut: Shortcut.digit("3"),
                    action: { }
                )

                StatusBarItem(
                    label: "Exit",
                    shortcut: Shortcut.letter("e"),
                    action: { }
                )
            }
            ```
        }

        @Step {
            Test your shortcuts:

            ```bash
            swift run
            ```

            Press number keys to jump directly to menu items.
        }
    }
}

## Next Steps

You've created an interactive menu-driven application!

- Learn about <doc:Focus> for advanced focus management
- Explore <doc:StateManagement> for more complex state patterns
- Try building a <doc:BuildThemableUI> with theme switching
- Check out <doc:Appearance> for custom styling
