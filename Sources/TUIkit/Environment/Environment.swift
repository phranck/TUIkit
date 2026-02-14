//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Environment.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - Environment Modifier

/// A modifier that injects a value into the environment for child views.
///
/// `EnvironmentModifier` conforms to both `View` and ``Renderable``.
/// Because ``renderToBuffer(_:context:)`` checks `Renderable` first,
/// the `body` property below is **never called during rendering**.
/// It exists only to satisfy the `View` protocol requirement.
/// All actual work happens in `renderToBuffer(context:)`.
struct EnvironmentModifier<Content: View, V>: View {
    /// The content view.
    let content: Content

    /// The key path to modify.
    let keyPath: WritableKeyPath<EnvironmentValues, V>

    /// The value to inject.
    let value: V

    /// Not used during rendering — ``Renderable`` conformance takes priority.
    var body: some View {
        content
    }
}

extension EnvironmentModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Create modified environment and render content with it.
        // The modified context carries the environment through the render tree —
        // no global state sync needed.
        let modifiedEnvironment = context.environment.setting(keyPath, to: value)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)
        return TUIkit.renderToBuffer(content, context: modifiedContext)
    }
}

// MARK: - Badge Environment Key

/// Environment key for badge values.
private struct BadgeKey: EnvironmentKey {
    static let defaultValue: BadgeValue? = nil
}

extension EnvironmentValues {
    /// The current badge value.
    ///
    /// Used to display decorative badges on list rows or other views.
    /// Set via `.badge()` modifier on views.
    var badgeValue: BadgeValue? {
        get { self[BadgeKey.self] }
        set { self[BadgeKey.self] = newValue }
    }
}

// MARK: - List Style Environment Key

/// Environment key for list styles.
private struct ListStyleKey: EnvironmentKey {
    static let defaultValue: any ListStyle = InsetGroupedListStyle()
}

extension EnvironmentValues {
    /// The current list style.
    ///
    /// Controls how lists render, including borders, padding, and row backgrounds.
    /// Set via `.listStyle()` modifier on List views.
    /// Default: ``InsetGroupedListStyle`` (bordered with alternating rows).
    var listStyle: any ListStyle {
        get { self[ListStyleKey.self] }
        set { self[ListStyleKey.self] = newValue }
    }
}

// MARK: - Selection Disabled Environment Key

/// Environment key for selection disabled state.
private struct SelectionDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// Whether selection is disabled for this view.
    ///
    /// When true, the view cannot be selected in a List.
    /// Set via `.selectionDisabled()` modifier.
    var isSelectionDisabled: Bool {
        get { self[SelectionDisabledKey.self] }
        set { self[SelectionDisabledKey.self] = newValue }
    }
}
