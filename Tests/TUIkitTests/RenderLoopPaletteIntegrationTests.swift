//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderLoopPaletteIntegrationTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

private struct DistinctBackgroundPalette: Palette {
    let id = "distinct-bg"
    let name = "Distinct BG"
    let background = Color.red
    let foreground = Color.white
    let accent = Color.cyan
    let success = Color.green
    let warning = Color.yellow
    let error = Color.magenta
    let info = Color.blue
    let border = Color.brightBlack
    let statusBarBackground = Color.green
    let appHeaderBackground = Color.blue
}

@MainActor
@Suite("Render Loop Palette Integration Tests")
struct RenderLoopPaletteIntegrationTests {

    @Test("RenderBackgroundCodes map each surface to the correct palette token")
    func renderBackgroundCodesUseSurfaceTokens() {
        let palette = DistinctBackgroundPalette()
        let codes = RenderBackgroundCodes(palette: palette)

        #expect(codes.content == ANSIRenderer.backgroundCode(for: palette.background))
        #expect(codes.appHeader == ANSIRenderer.backgroundCode(for: palette.appHeaderBackground))
        #expect(codes.statusBar == ANSIRenderer.backgroundCode(for: palette.statusBarBackground))
        #expect(codes.content != codes.statusBar)
        #expect(codes.content != codes.appHeader)
    }

    @Test("WindowGroup root palette override is discovered for built-in palettes")
    func discoversSystemPaletteOverride() {
        let scene = WindowGroup {
            Text("Hello")
                .palette(SystemPalette(.blue))
        }

        #expect(scene.rootPaletteOverride()?.id == "blue")
    }

    @Test("WindowGroup root palette override supports custom palettes")
    func discoversCustomPaletteOverride() {
        let palette = DistinctBackgroundPalette()
        let scene = WindowGroup {
            Text("Hello")
                .palette(palette)
        }

        #expect(scene.rootPaletteOverride()?.id == palette.id)
        #expect(scene.rootPaletteOverride()?.statusBarBackground == palette.statusBarBackground)
    }

    @Test("WindowGroup root palette override prefers the outermost palette")
    func outermostPaletteWins() {
        let scene = WindowGroup {
            VStack {
                Text("Nested")
                    .palette(SystemPalette(.blue))
            }
            .palette(SystemPalette(.amber))
        }

        #expect(scene.rootPaletteOverride()?.id == "amber")
    }

    @Test("WindowGroup without root palette override returns nil")
    func noRootOverrideReturnsNil() {
        let scene = WindowGroup {
            VStack {
                Text("Nested")
                    .palette(SystemPalette(.blue))
            }
        }

        #expect(scene.rootPaletteOverride() == nil)
    }
}
