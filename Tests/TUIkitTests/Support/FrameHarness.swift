//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FrameHarness.swift
//
//  License: MIT

@testable import TUIkit

/// Drives a `RenderLoop` against a `MockTerminal` for one app instance.
///
/// Unlike `RuntimeCharacterizationHarness` (which renders single views via
/// `renderToBuffer`), this harness exercises the full frame pipeline —
/// including the first-frame header measurement and the header-correction
/// pass — which is exactly where phase separation matters.
///
/// The default terminal is 40×24 with system status-bar items hidden, so a
/// frame's content height is `24 − headerHeight` and height-gated fixtures
/// can distinguish the measurement pass (full 24 rows) from output passes.
///
/// Tests that need deterministic services (stub image loaders, injected
/// clocks, …) pass their own `TUIContext`; by default a fresh one is created.
@MainActor
final class FrameHarness<A: App> {
    let app: A
    let tuiContext: TUIContext
    let terminal: MockTerminal

    private let renderLoop: RenderLoop<A>

    init(app: A, width: Int = 40, height: Int = 24, tuiContext: TUIContext = TUIContext()) {
        let terminal = MockTerminal()
        terminal.size = (width, height)
        tuiContext.statusBar.showSystemItems = false

        self.app = app
        self.tuiContext = tuiContext
        self.terminal = terminal
        self.renderLoop = RenderLoop(
            app: app,
            terminal: terminal,
            statusBar: tuiContext.statusBar,
            appHeader: tuiContext.appHeader,
            focusManager: tuiContext.focusManager,
            paletteManager: tuiContext.paletteManager,
            appearanceManager: tuiContext.appearanceManager,
            tuiContext: tuiContext
        )
    }

    func renderFrame() {
        renderLoop.render()
    }
}
