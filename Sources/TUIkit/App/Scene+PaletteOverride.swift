//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Scene+PaletteOverride.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Root Palette Discovery

/// A scene that can provide a root-level palette override.
///
/// `RenderLoop` uses this to keep out-of-tree surfaces (status bar, app header)
/// aligned with `.palette(...)` applied at the root view level.
@MainActor
internal protocol RootPaletteOverrideProvidingScene: Scene {
    /// Returns the root palette override, if present.
    func rootPaletteOverride() -> (any Palette)?
}

/// Type-erased access to `EnvironmentModifier` internals.
///
/// This is intentionally limited to root modifier chain discovery.
@MainActor
private protocol AnyEnvironmentModifierNode {
    var anyEnvironmentKeyPath: AnyKeyPath { get }
    var anyEnvironmentValue: Any { get }
    var anyEnvironmentContent: Any { get }
}

@MainActor
extension EnvironmentModifier: AnyEnvironmentModifierNode {
    fileprivate var anyEnvironmentKeyPath: AnyKeyPath { keyPath }
    fileprivate var anyEnvironmentValue: Any { value }
    fileprivate var anyEnvironmentContent: Any { content }
}

@MainActor
extension WindowGroup: RootPaletteOverrideProvidingScene {
    func rootPaletteOverride() -> (any Palette)? {
        var current: Any = content

        while let modifier = current as? any AnyEnvironmentModifierNode {
            if modifier.anyEnvironmentKeyPath == \EnvironmentValues.palette,
               let palette = modifier.anyEnvironmentValue as? any Palette {
                return palette
            }
            current = modifier.anyEnvironmentContent
        }

        return nil
    }
}
