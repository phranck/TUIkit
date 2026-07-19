//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewRendererTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("ViewRenderer Tests", .serialized)
struct ViewRendererTests {
    @Test("Standalone rendering supports composite views and property wrappers")
    func standaloneRenderingSupportsCompositeViewsAndPropertyWrappers() {
        let terminal = MockTerminal()
        terminal.size = (40, 6)
        let tuiContext = TUIContext()
        tuiContext.storageBackend.setValue("owned", forKey: "renderer-name")
        let renderer = ViewRenderer(terminal: terminal, tuiContext: tuiContext)

        renderer.render {
            RendererPropertyWrapperView()
        }

        #expect(terminal.outputContains("owned:7"))
        #expect(tuiContext.stateStorage.count == 1)
        #expect(terminal.isRawModeEnabled == false)
        #expect(terminal.isInAlternateScreen == false)
    }

    @Test("Standalone builder receives the runtime environment")
    func standaloneBuilderReceivesRuntimeEnvironment() {
        let terminal = MockTerminal()
        let tuiContext = TUIContext()
        tuiContext.localizationService.setLanguage(.german)
        let renderer = ViewRenderer(terminal: terminal, tuiContext: tuiContext)

        renderer.render {
            Text(localized: "button.cancel")
        }

        #expect(terminal.outputContains("Abbrechen"))
    }

    @Test("App rendering accepts an injected terminal session")
    func appRenderingAcceptsInjectedTerminalSession() {
        let terminal = MockTerminal()
        terminal.size = (40, 6)
        let tuiContext = TUIContext()
        tuiContext.statusBar.showSystemItems = false
        tuiContext.storageBackend.setValue("owned", forKey: "renderer-name")
        let renderLoop = RenderLoop(
            app: RendererTestApp(),
            terminal: terminal,
            statusBar: tuiContext.statusBar,
            appHeader: tuiContext.appHeader,
            focusManager: tuiContext.focusManager,
            paletteManager: tuiContext.paletteManager,
            appearanceManager: tuiContext.appearanceManager,
            tuiContext: tuiContext
        )

        renderLoop.render()

        #expect(terminal.outputContains("owned:7"))
        #expect(terminal.isRawModeEnabled == false)
        #expect(terminal.isInAlternateScreen == false)
    }
}

private struct RendererPropertyWrapperView: View {
    @State private var value = 7
    @AppStorage("renderer-name") private var name = "fallback"

    var body: some View {
        VStack {
            Text("\(name):\(value)")
        }
    }
}

@MainActor
private struct RendererTestApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            RendererPropertyWrapperView()
        }
    }
}
