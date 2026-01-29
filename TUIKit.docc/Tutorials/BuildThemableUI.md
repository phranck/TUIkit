# Building a Themable UI

Create an application with dynamic theme switching and persistence.

@Intro(title: "Build a Themable App") {
    Learn how to integrate TUIKit's theming system into your application,
    allowing users to switch between themes and persist their preference.

    You'll work with the theme environment, theme manager, and storage to
    create a professional themable application.
}

## Overview

In this tutorial, you'll create an app that features:

- Theme environment integration
- Dynamic theme switching
- Persisted theme preference
- Visual theme selection UI

@Section(title: "Set Up Theme Storage") {
    @ContentAndMedia {
        Use `@AppStorage` to remember the user's theme choice across sessions.
    }

    @Steps {
        @Step {
            Create an app that stores the selected theme:

            ```swift
            import TUIKit

            @main
            struct ThemableApp: App {
                @AppStorage("selectedTheme") var selectedThemeName: String = "green"

                var body: some Scene {
                    WindowGroup {
                        ContentView()
                            .environment(\.theme, themeForName(selectedThemeName))
                    }
                }

                func themeForName(_ name: String) -> Theme {
                    switch name {
                    case "amber":
                        return AmberPhosphorTheme()
                    case "white":
                        return WhitePhosphorTheme()
                    case "red":
                        return RedPhosphorTheme()
                    default:
                        return GreenPhosphorTheme()
                    }
                }
            }

            struct ContentView: View {
                var body: some View {
                    VStack(spacing: 2) {
                        Text("Themable Application")
                            .bold()
                            .foregroundColor(.theme.accent)

                        Spacer()

                        Text("Select a theme to customize the appearance")
                            .foregroundColor(.theme.foregroundSecondary)

                        Spacer()
                    }
                    .padding()
                }
            }
            ```

            `@AppStorage("selectedTheme")` automatically persists the theme choice.
            When the app restarts, it loads the saved theme.
        }

        @Step {
            Run your app:

            ```bash
            swift run
            ```

            The app launches with the default Green theme.
        }
    }
}

@Section(title: "Create Theme Selection UI") {
    @ContentAndMedia {
        Display the 4 available themes and let users select one.
    }

    @Steps {
        @Step {
            Add a theme menu:

            ```swift
            @main
            struct ThemableApp: App {
                @AppStorage("selectedTheme") var selectedThemeName: String = "green"

                var body: some Scene {
                    WindowGroup {
                        ContentView(selectedThemeName: $selectedThemeName)
                            .environment(\.theme, themeForName(selectedThemeName))
                    }
                }

                func themeForName(_ name: String) -> Theme {
                    // ... same as before
                }
            }

            struct ContentView: View {
                @Binding var selectedThemeName: String

                let themes = [
                    ("green", "🟢 Green (Default)"),
                    ("amber", "🟡 Amber"),
                    ("white", "⚪ White"),
                    ("red", "🔴 Red")
                ]

                var body: some View {
                    VStack(spacing: 2) {
                        Text("Themable Application")
                            .bold()
                            .foregroundColor(.theme.accent)

                        Spacer()

                        Text("Select a theme:")
                            .bold()

                        Menu(
                            items: themes.map { id, label in
                                MenuItem(label, id: id)
                            },
                            selection: $selectedThemeName
                        )

                        Spacer()

                        Text("Current: \(themeName(selectedThemeName))")
                            .foregroundColor(.theme.foregroundSecondary)

                        Spacer()
                    }
                    .padding()
                }

                func themeName(_ id: String) -> String {
                    themes.first(where: { $0.0 == id })?.1 ?? id
                }
            }
            ```

            Pass `$selectedThemeName` as a binding to allow the menu to change it.
            The environment automatically updates because it depends on this value.
        }

        @Step {
            Test theme switching:

            ```bash
            swift run
            ```

            Use Tab/Arrow keys to select different themes.
            Notice the colors change immediately!
        }
    }
}

@Section(title: "Display Theme Colors") {
    @ContentAndMedia {
        Show a visual preview of the current theme's colors.
    }

    @Steps {
        @Step {
            Add a color preview:

            ```swift
            struct ContentView: View {
                @Binding var selectedThemeName: String
                @Environment(\.theme) var theme

                let themes = [
                    ("green", "🟢 Green (Default)"),
                    ("amber", "🟡 Amber"),
                    ("white", "⚪ White"),
                    ("red", "🔴 Red")
                ]

                var body: some View {
                    VStack(spacing: 2) {
                        Text("Themable Application")
                            .bold()
                            .foregroundColor(.theme.accent)

                        Spacer()

                        Text("Select a theme:").bold()

                        Menu(
                            items: themes.map { id, label in
                                MenuItem(label, id: id)
                            },
                            selection: $selectedThemeName
                        )

                        Spacer()

                        // Color preview box
                        VStack(spacing: 1) {
                            Text("Theme Colors")
                                .bold()

                            HStack(spacing: 1) {
                                Text(" ").background(theme.foreground)
                                Text(" ").background(theme.accent)
                                Text(" ").background(theme.border)
                                Text(" ").background(theme.warning)
                            }

                            Text("Foreground | Accent | Border | Warning")
                                .foregroundColor(.theme.foregroundSecondary)
                        }
                        .padding(1)
                        .border(.rounded)

                        Spacer()
                    }
                    .padding()
                }

                func themeName(_ id: String) -> String {
                    themes.first(where: { $0.0 == id })?.1 ?? id
                }
            }
            ```

            `@Environment(\.theme)` gives access to the current theme.
            Use `theme.foreground`, `theme.accent`, etc. to access colors.
        }

        @Step {
            Run the app:

            ```bash
            swift run
            ```

            Switch themes and see the color preview update.
        }
    }
}

@Section(title: "Add Theme Shortcuts and Status Bar") {
    @ContentAndMedia {
        Let users cycle themes quickly with keyboard shortcuts.
    }

    @Steps {
        @Step {
            Add quick theme cycling:

            ```swift
            struct ContentView: View {
                @Binding var selectedThemeName: String
                @Environment(\.theme) var theme

                let themes = [
                    ("green", "🟢 Green (Default)"),
                    ("amber", "🟡 Amber"),
                    ("white", "⚪ White"),
                    ("red", "🔴 Red")
                ]

                let themeIds = ["green", "amber", "white", "red"]

                var body: some View {
                    VStack(spacing: 2) {
                        // ... menu UI as before ...

                        Spacer()
                    }
                    .padding()
                    .onKeyPress { event in
                        if event.key == .character("t") {
                            // Cycle to next theme
                            if let currentIndex = themeIds.firstIndex(of: selectedThemeName) {
                                let nextIndex = (currentIndex + 1) % themeIds.count
                                selectedThemeName = themeIds[nextIndex]
                            }
                            return true
                        }
                        return false
                    }
                    .statusBarItems {
                        StatusBarItem(
                            label: "Cycle Theme",
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

                func themeName(_ id: String) -> String {
                    themes.first(where: { $0.0 == id })?.1 ?? id
                }
            }
            ```

            Now users can press `t` to quickly cycle through themes.
        }

        @Step {
            Test theme cycling:

            ```bash
            swift run
            ```

            Press `t` repeatedly to cycle through all 4 themes.
            The selection updates and the preview colors change.
        }
    }
}

@Section(title: "Enhance with Appearance Switching") {
    @ContentAndMedia {
        Add appearance style switching alongside theme switching.
    }

    @Steps {
        @Step {
            Add appearance cycling:

            ```swift
            @main
            struct ThemableApp: App {
                @AppStorage("selectedTheme") var selectedThemeName: String = "green"
                @AppStorage("selectedAppearance") var selectedAppearance: String = "rounded"

                var body: some Scene {
                    WindowGroup {
                        ContentView(
                            selectedThemeName: $selectedThemeName,
                            selectedAppearance: $selectedAppearance
                        )
                        .environment(\.theme, themeForName(selectedThemeName))
                        .environment(\.appearance, appearanceForName(selectedAppearance))
                    }
                }

                func themeForName(_ name: String) -> Theme {
                    // ... existing code ...
                }

                func appearanceForName(_ name: String) -> Appearance {
                    switch name {
                    case "line":
                        return .line
                    case "doubled":
                        return .doubleLine
                    case "heavy":
                        return .heavy
                    case "block":
                        return .block
                    default:
                        return .rounded
                    }
                }
            }
            ```

            Now users can customize both theme AND appearance style!
        }

        @Step {
            The changes are automatically persisted with `@AppStorage`.
            Run the app:

            ```bash
            swift run
            ```

            Select a theme and appearance, exit with `q`, and run again.
            Your selection is remembered!
        }
    }
}

## Next Steps

Congratulations! You've built a fully themed, customizable application.

- Learn more about <doc:Theming> for creating custom themes
- Explore <doc:Appearance> for structural styles
- See <doc:StateManagement> for advanced state patterns
- Check the <doc:Architecture> overview for deeper understanding
