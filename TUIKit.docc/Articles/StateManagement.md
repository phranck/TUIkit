# State Management

Learn how to manage application state and data flow in TUIKit.

## Overview

TUIKit provides several mechanisms for managing state:

- **`@State`**: Local view state
- **`@Environment`**: Top-down data flow
- **`Binding`**: Two-way data binding
- **`@AppStorage`**: Persistent application settings
- **`@SceneStorage`**: Scene-specific state restoration

## @State Property Wrapper

`@State` stores local state within a view and automatically triggers re-renders when the value changes:

```swift
struct Counter: View {
    @State var count: Int = 0

    var body: some View {
        VStack(spacing: 1) {
            Text("Count: \(count)")
                .bold()

            HStack(spacing: 2) {
                Button("Decrement") { count -= 1 }
                Button("Increment") { count += 1 }
            }
        }
    }
}
```

### Rules for @State

- Declare as `private` to prevent external modification
- Initialize with a default value
- Use only in views, not in view models
- State is destroyed when view is removed from hierarchy

```swift
struct InputForm: View {
    @State private var name: String = ""
    @State private var age: Int = 0
    @State private var agreed: Bool = false

    var body: some View {
        VStack(spacing: 1) {
            // View content
        }
    }
}
```

## Binding

A `Binding` creates a two-way connection between a view and a state variable:

```swift
struct Parent: View {
    @State var isExpanded: Bool = false

    var body: some View {
        VStack {
            Child(isExpanded: $isExpanded)
        }
    }
}

struct Child: View {
    @Binding var isExpanded: Bool

    var body: some View {
        Button(isExpanded ? "Collapse" : "Expand") {
            isExpanded.toggle()
        }
    }
}
```

Use `$` to create a binding to a state property.

### Creating Custom Bindings

Create computed bindings for complex logic:

```swift
struct FilteredList: View {
    @State private var showDetails: Bool = false

    var detailsBinding: Binding<Bool> {
        Binding(
            get: { showDetails },
            set: { newValue in
                if newValue {
                    print("Details opened")
                }
                showDetails = newValue
            }
        )
    }

    var body: some View {
        Button("Toggle") {
            detailsBinding.wrappedValue.toggle()
        }
    }
}
```

## @Environment and Environment Keys

Environment provides top-down data flow to all child views:

```swift
struct App: View {
    var body: some View {
        VStack {
            ContentView()
                .environment(\.theme, customTheme)
        }
    }
}

struct ContentView: View {
    @Environment(\.theme) var theme

    var body: some View {
        Text("Using current theme")
            .foregroundColor(theme.foreground)
    }
}
```

### Custom Environment Keys

Define custom environment values:

```swift
struct UserPreferencesKey: EnvironmentKey {
    static let defaultValue = UserPreferences()
}

extension EnvironmentValues {
    var userPreferences: UserPreferences {
        get { self[UserPreferencesKey.self] }
        set { self[UserPreferencesKey.self] = newValue }
    }
}

// Usage
struct App: View {
    var body: some View {
        VStack {
            ContentView()
                .environment(\.userPreferences, UserPreferences(language: "de"))
        }
    }
}

struct ContentView: View {
    @Environment(\.userPreferences) var prefs

    var body: some View {
        Text("Language: \(prefs.language)")
    }
}
```

## @AppStorage

`@AppStorage` persists values to storage (UserDefaults on macOS, JSON file on Linux):

```swift
struct App: View {
    @AppStorage("theme") var selectedTheme: String = "green"
    @AppStorage("fontSize") var fontSize: Int = 12

    var body: some View {
        VStack {
            Text("Current theme: \(selectedTheme)")
            // Settings UI
        }
    }
}
```

Changes to `@AppStorage` variables are automatically saved and restored across app launches.

## @SceneStorage

`@SceneStorage` preserves state for the current scene:

```swift
struct MyScene: Scene {
    @SceneStorage("selectedTab") var selectedTab: String = "home"
    @SceneStorage("scrollPosition") var scrollPosition: Int = 0

    var body: some Scene {
        WindowGroup {
            VStack {
                if selectedTab == "home" {
                    HomeView()
                }
            }
        }
    }
}
```

## Data Flow Pattern

### Recommended Pattern

1. **Local state**: Use `@State` for temporary UI state
2. **Shared state**: Use `@Environment` to pass to child views
3. **Persistent state**: Use `@AppStorage` for settings
4. **Child updates**: Use `@Binding` to let children modify parent state

```swift
@main
struct MyApp: App {
    // Persistent settings
    @AppStorage("theme") var theme: String = "green"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.theme, themeForString(theme))
        }
    }
}

struct ContentView: View {
    @Environment(\.theme) var theme
    @State private var showMenu: Bool = false

    var body: some View {
        VStack {
            if showMenu {
                MenuView(showing: $showMenu)
            }
        }
    }
}
```

## Related Topics

- ``State``
- ``Binding``
- ``@Environment``
- ``@AppStorage``
- ``@SceneStorage``
- ``EnvironmentKey``
- ``EnvironmentValues``
