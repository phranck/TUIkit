//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewEnvironmentKeys.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

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
