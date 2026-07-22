import TUIkit

@MainActor
func terminalScene() -> some Scene {
    WindowGroup {
        Text("Scene")
    }
}

// The documented issue-2 shape: scene-level palette on a WindowGroup.
@MainActor
func paletteScene() -> some Scene {
    WindowGroup {
        Text("Scene")
    }
    .palette(SystemPalette(.green))
}

@MainActor
func composedScene() -> some Scene {
    WindowGroup {
        Text("Scene")
    }
    .environment(\.scenePhase, .active)
    .appearance(.rounded)
}

@MainActor
private struct SceneApp: App {
    var body: some Scene {
        WindowGroup {
            Text("App")
        }
        .palette(SystemPalette(.amber))
    }
}
