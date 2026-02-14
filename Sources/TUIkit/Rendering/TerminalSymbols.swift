//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TerminalSymbols.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Terminal Symbols

/// Centralized Unicode symbols used throughout TUIkit's rendering.
///
/// Keeping all terminal drawing characters in one place ensures consistency
/// and makes it easy to adjust the visual style globally.
enum TerminalSymbols {

    // MARK: - Half-Block Caps

    /// Right half block (U+2590), used as opening cap for input controls.
    static let openCap: Character = "\u{2590}"

    /// Left half block (U+258C), used as closing cap for input controls.
    static let closeCap: Character = "\u{258C}"

    // MARK: - Arrows

    /// Left-pointing triangle (U+25C0), used by Stepper and Slider.
    static let leftArrow = "\u{25C0}"

    /// Right-pointing triangle (U+25B6), used by Stepper and Slider.
    static let rightArrow = "\u{25B6}"

    // MARK: - Radio Button Indicators

    /// Filled circle for selected/focused radio button.
    static let radioSelected = "\u{25CF}"

    /// Empty circle for unselected radio button.
    static let radioUnselected = "\u{25EF}"

    // MARK: - Text Masking

    /// Bullet character (U+25CF) used for masking text in SecureField.
    static let maskBullet: Character = "\u{25CF}"
}
