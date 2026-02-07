//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ButtonRow.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Button Row Helper

/// A horizontal row of buttons.
///
/// Use this to display multiple buttons side by side with consistent spacing.
///
/// # Example
///
/// ```swift
/// ButtonRow {
///     Button("Cancel", style: .plain) { dismiss() }
///     Button("OK", style: .primary) { confirm() }
/// }
/// ```
public struct ButtonRow: View {
    private let buttons: [Button]
    private let spacing: Int

    /// Creates a button row.
    ///
    /// - Parameters:
    ///   - spacing: The horizontal spacing between buttons (default: 2).
    ///   - buttons: The buttons to display.
    public init(spacing: Int = 2, @ButtonRowBuilder _ buttons: () -> [Button]) {
        self.spacing = spacing
        self.buttons = buttons()
    }

    public var body: Never {
        fatalError("ButtonRow renders via Renderable")
    }
}

// MARK: - ButtonRow Builder

/// A result builder that constructs arrays of buttons for use in ``ButtonRow``.
///
/// `ButtonRowBuilder` enables the declarative syntax for defining multiple
/// buttons within a ``ButtonRow``. You don't use this type directly; instead,
/// the `@ButtonRowBuilder` attribute is applied to the trailing closure of
/// ``ButtonRow/init(spacing:_:)``.
///
/// ## Overview
///
/// When you write:
///
/// ```swift
/// ButtonRow {
///     Button("Cancel", style: .plain) { dismiss() }
///     Button("OK", style: .primary) { confirm() }
/// }
/// ```
///
/// The `@ButtonRowBuilder` attribute transforms this closure into an array
/// of ``Button`` instances that the row can lay out horizontally.
///
/// ## Supported Control Flow
///
/// The builder supports:
/// - Multiple button expressions
/// - `if`/`else` conditionals
/// - `if let` optional binding
/// - `for`...`in` loops
@resultBuilder
public struct ButtonRowBuilder {
    /// Combines multiple buttons into a single array.
    public static func buildBlock(_ buttons: Button...) -> [Button] {
        buttons
    }

    /// Combines an array of button arrays (from `for` loops).
    public static func buildArray(_ components: [[Button]]) -> [Button] {
        components.flatMap { $0 }
    }

    /// Handles optional button arrays (from `if` without `else`).
    public static func buildOptional(_ component: [Button]?) -> [Button] {
        component ?? []
    }

    /// Handles the first branch of an `if`/`else`.
    public static func buildEither(first component: [Button]) -> [Button] {
        component
    }

    /// Handles the second branch of an `if`/`else`.
    public static func buildEither(second component: [Button]) -> [Button] {
        component
    }
}

// MARK: - ButtonRow Rendering

extension ButtonRow: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard !buttons.isEmpty else {
            return FrameBuffer(lines: [])
        }

        // Render each button
        var buttonBuffers: [FrameBuffer] = []
        for button in buttons {
            let buffer = TUIkit.renderToBuffer(button, context: context)
            buttonBuffers.append(buffer)
        }

        // Find the maximum height
        let maxHeight = buttonBuffers.map { $0.height }.max() ?? 0

        // Calculate total width needed (buttons + spacing)
        let totalButtonWidth = buttonBuffers.reduce(0) { $0 + $1.width }
        let totalSpacingWidth = max(0, buttonBuffers.count - 1) * spacing
        let totalNeededWidth = totalButtonWidth + totalSpacingWidth

        // Available width from context
        let availableWidth = context.availableWidth

        // Right-align: calculate left padding
        let leftPadding = max(0, availableWidth - totalNeededWidth)

        // Combine horizontally (right-aligned)
        var resultLines: [String] = Array(repeating: "", count: maxHeight)
        let spacer = String(repeating: " ", count: spacing)

        for lineIndex in 0..<maxHeight {
            // Add left padding
            resultLines[lineIndex] = String(repeating: " ", count: leftPadding)

            // Add buttons
            for (index, buffer) in buttonBuffers.enumerated() {
                let buttonWidth = buffer.width

                if index > 0 {
                    resultLines[lineIndex] += spacer
                }

                if lineIndex < buffer.height {
                    resultLines[lineIndex] += buffer.lines[lineIndex]
                } else {
                    // Pad with spaces if this button is shorter
                    resultLines[lineIndex] += String(repeating: " ", count: buttonWidth)
                }
            }
        }

        return FrameBuffer(lines: resultLines)
    }
}
