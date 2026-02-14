//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewConstants.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - View Constants

/// Centralized visual constants used throughout TUIkit's views.
///
/// Keeping opacity values and other visual parameters in one place ensures
/// consistency and makes global adjustments easy. All values are `Double`
/// for direct use with ``Color/opacity(_:)``.
enum ViewConstants {

    // MARK: - Focus & Selection Opacity

    /// Minimum accent opacity during focus pulsing animation (dim phase).
    static let focusPulseMin: Double = 0.35

    /// Maximum accent opacity during focus pulsing animation (bright phase).
    static let focusPulseMax: Double = 0.50

    /// Background opacity for selected (but unfocused) rows.
    static let selectedBackground: Double = 0.25

    /// Background opacity for alternating row tinting.
    static let alternatingRowBackground: Double = 0.15

    /// Accent opacity for focus borders and indicator caps in their dim state.
    static let focusBorderDim: Double = 0.20

    /// Foreground opacity for disabled interactive controls.
    static let disabledForeground: Double = 0.50

    /// Accent opacity for selection indicator bullets.
    static let selectionIndicator: Double = 0.60

    /// Accent opacity for focused button caps pulsing bright phase.
    static let buttonCapPulseBright: Double = 0.45

    // MARK: - Default Strings

    /// Default placeholder text for empty List and Table views.
    static let emptyListPlaceholder = "No items"
}

// MARK: - EdgeInsets Defaults

extension EdgeInsets {
    /// Default insets for containers (Card, Panel, etc.): 1 horizontal, 0 vertical.
    static let containerDefault = EdgeInsets(horizontal: 1, vertical: 0)

    /// Default insets for dialogs: 2 horizontal, 1 vertical.
    static let dialogDefault = EdgeInsets(horizontal: 2, vertical: 1)
}
