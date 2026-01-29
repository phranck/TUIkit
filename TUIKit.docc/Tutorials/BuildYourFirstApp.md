# Building Your First App

Create a simple counter application to learn TUIKit basics.

@Intro(title: "Create Your First TUIKit App") {
    Learn the fundamentals of building a terminal user interface with TUIKit
    by creating a simple counter application.

    You'll learn how to set up an `@main` app, use `@State` for local state,
    add interactive buttons, and use basic layout with `VStack` and `HStack`.
}

## Overview

In this tutorial, you'll build a working counter app with increment/decrement buttons.
This will teach you:

- Creating an app with the `@main` attribute
- Using `VStack` and `HStack` for layout
- Handling button taps with `@State`
- Running and testing your app

@Section(title: "Create the App Entry Point") {
    @ContentAndMedia {
        Every TUIKit app needs an entry point decorated with `@main`.
        This tells Swift to use your app as the entry point for the program.
    }

    @Steps {
        @Step {
            Create a new file called `main.swift` in your project:

            ```swift
            import TUIKit

            @main
            struct CounterApp: App {
                var body: some Scene {
                    WindowGroup {
                        Text("Hello, TUIKit!")
                    }
                }
            }
            ```

            The `@main` attribute marks this as the app entry point.
            `WindowGroup` represents the main window of your terminal app.
        }

        @Step {
            Run your app with:

            ```bash
            swift run
            ```

            You should see "Hello, TUIKit!" displayed in the terminal.
        }
    }
}

@Section(title: "Add Layout and Text") {
    @ContentAndMedia {
        Now let's organize content with `VStack` (vertical layout).
        We'll add a title and multiple text lines.
    }

    @Steps {
        @Step {
            Modify the `body` to use `VStack`:

            ```swift
            @main
            struct CounterApp: App {
                var body: some Scene {
                    WindowGroup {
                        VStack(spacing: 1) {
                            Text("Counter App")
                                .bold()

                            Text("Simple counter to learn TUIKit")
                                .foregroundColor(.theme.foregroundSecondary)

                            Spacer()

                            Text("Current count: 0")

                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            ```

            - `VStack(spacing: 1)` arranges content vertically with 1-unit spacing
            - `.bold()` makes the title bold
            - `.foregroundColor()` colors text
            - `Spacer()` creates flexible vertical space
            - `.padding()` adds space around all edges
        }

        @Step {
            Run the app again:

            ```bash
            swift run
            ```

            Now you should see a nicely formatted display with title,
            description, and spacing.
        }
    }
}

@Section(title: "Add Interactive State") {
    @ContentAndMedia {
        Use `@State` to track the counter value and re-render when it changes.
        This makes your app interactive!
    }

    @Steps {
        @Step {
            Add a `@State` property for the counter:

            ```swift
            @main
            struct CounterApp: App {
                @State private var count: Int = 0

                var body: some Scene {
                    WindowGroup {
                        VStack(spacing: 1) {
                            Text("Counter App")
                                .bold()

                            Text("Simple counter to learn TUIKit")
                                .foregroundColor(.theme.foregroundSecondary)

                            Spacer()

                            Text("Current count: \(count)")

                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            ```

            The `@State` property wrapper stores local state. When `count` changes,
            the view automatically re-renders.
        }
    }
}

@Section(title: "Add Buttons") {
    @ContentAndMedia {
        Now add buttons to increment and decrement the counter.
        Use `HStack` to arrange them horizontally.
    }

    @Steps {
        @Step {
            Add buttons using `HStack`:

            ```swift
            @main
            struct CounterApp: App {
                @State private var count: Int = 0

                var body: some Scene {
                    WindowGroup {
                        VStack(spacing: 1) {
                            Text("Counter App")
                                .bold()

                            Text("Simple counter to learn TUIKit")
                                .foregroundColor(.theme.foregroundSecondary)

                            Spacer()

                            Text("Current count: \(count)")

                            HStack(spacing: 2) {
                                Button("Decrement") { count -= 1 }
                                Button("Increment") { count += 1 }
                            }

                            Spacer()

                            Text("Press 'q' to quit")
                                .foregroundColor(.theme.foregroundTertiary)
                        }
                        .padding()
                    }
                }
            }
            ```

            - `HStack(spacing: 2)` arranges buttons horizontally
            - `Button(label) { action }` creates a clickable button
            - The closure after the label runs when the button is pressed
        }

        @Step {
            Run your app:

            ```bash
            swift run
            ```

            Now use Tab to navigate to the buttons and press Enter to increment/decrement.
            The counter value updates in real-time!
        }
    }
}

@Section(title: "Test and Iterate") {
    @ContentAndMedia {
        Test your counter app and try making improvements.
    }

    @Steps {
        @Step {
            Test the following interactions:

            - Press `Tab` to move focus to the next button
            - Press `Shift+Tab` to move focus backward
            - Press `Enter` when a button is focused to activate it
            - Watch the counter update
            - Press `q` to quit the app
            - Press `t` to cycle through themes
            - Press `a` to cycle through appearance styles
        }

        @Step {
            Try these enhancements:

            Add a reset button:

            ```swift
            HStack(spacing: 2) {
                Button("Decrement") { count = max(0, count - 1) }
                Button("Reset") { count = 0 }
                Button("Increment") { count += 1 }
            }
            ```

            Or add a border around the counter:

            ```swift
            Text("Current count: \(count)")
                .bold()
                .padding(1)
                .border(.rounded)
            ```
        }
    }
}

## Next Steps

Congratulations! You've built your first TUIKit app.

- Learn more about <doc:StateManagement> for complex state scenarios
- Explore <doc:Theming> to customize colors
- Try building an interactive <doc:BuildInteractiveMenu>
- Check out <doc:Modifiers> for more styling options
