//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarSystemItemsModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - StatusBarSystemItemsModifier

/// A modifier that configures which system items are shown in the status bar.
///
/// System items are the built-in shortcuts like quit (`q`), theme (`t`),
/// and appearance (`a`). By default, only quit is shown.
///
/// # Example
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///         .statusBarSystemItems(theme: true, appearance: true)
///     }
/// }
/// ```
struct StatusBarSystemItemsModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// Whether to show the theme item (`t`).
    let showTheme: Bool

    /// Whether to show the appearance item (`a`).
    let showAppearance: Bool

    var body: Never {
        fatalError("StatusBarSystemItemsModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension StatusBarSystemItemsModifier: Renderable {
    func renderToBuffer(context renderContext: RenderContext) -> FrameBuffer {
        let statusBar = renderContext.environment.statusBar
        statusBar.showThemeItem = showTheme
        statusBar.showAppearanceItem = showAppearance

        return TUIkit.renderToBuffer(content, context: renderContext)
    }
}

// MARK: - View Extension

public extension View {
    /// Configures which system items are shown in the status bar.
    ///
    /// System items are the built-in shortcuts:
    /// - **quit** (`q`): Always shown by default
    /// - **theme** (`t`): Cycles through available color themes
    /// - **appearance** (`a`): Cycles through border appearances
    ///
    /// # Example
    ///
    /// ```swift
    /// ContentView()
    ///     .statusBarSystemItems(theme: true, appearance: true)
    /// ```
    ///
    /// - Parameters:
    ///   - theme: Whether to show the theme switcher (`t theme`). Default is `false`.
    ///   - appearance: Whether to show the appearance switcher (`a appearance`). Default is `false`.
    /// - Returns: A view with the configured system items.
    func statusBarSystemItems(
        theme: Bool = false,
        appearance: Bool = false
    ) -> some View {
        StatusBarSystemItemsModifier(
            content: self,
            showTheme: theme,
            showAppearance: appearance
        )
    }
}
