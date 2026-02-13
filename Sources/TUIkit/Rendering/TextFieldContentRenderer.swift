//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TextFieldContentRenderer.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Text Field Content Renderer

/// Shared rendering logic for text input fields (TextField, SecureField).
///
/// Both TextField and SecureField share identical rendering patterns for
/// prompt display, cursor positioning, horizontal scrolling, and selection
/// highlighting. The only difference is how characters are displayed:
/// TextField shows the actual text, SecureField shows bullet characters.
///
/// This renderer extracts that shared logic. The caller provides a
/// `displayCharacter` closure that maps text indices to display characters.
@MainActor
struct TextFieldContentRenderer {

    /// The prompt view shown when the field is empty and unfocused.
    let prompt: Text?

    /// Whether the field is disabled.
    let isDisabled: Bool

    /// Returns the display character for a given index in the text.
    /// For TextField: the actual character. For SecureField: a bullet.
    let displayCharacter: (_ index: Int, _ text: String) -> Character

    // MARK: - Content Building

    /// Builds the complete field content based on current state.
    func buildContent(
        text: String,
        cursorPosition: Int,
        selectionRange: Range<Int>?,
        isFocused: Bool,
        palette: any Palette,
        cursorStyle: TextCursorStyle,
        cursorTimer: CursorTimer?,
        contentWidth: Int
    ) -> String {
        let isEmpty = text.isEmpty
        let backgroundColor = palette.accent.opacity(0.2)

        if isEmpty && !isFocused && prompt != nil {
            return buildPromptContent(palette: palette, background: backgroundColor, width: contentWidth)
        } else if isFocused {
            return buildTextWithCursor(
                text: text,
                cursorPosition: cursorPosition,
                selectionRange: selectionRange,
                palette: palette,
                cursorStyle: cursorStyle,
                cursorTimer: cursorTimer,
                background: backgroundColor,
                width: contentWidth
            )
        } else {
            return buildTextContent(
                text: text,
                palette: palette,
                background: backgroundColor,
                width: contentWidth
            )
        }
    }

    // MARK: - Prompt

    /// Builds the prompt content (shown when empty and unfocused).
    private func buildPromptContent(palette: any Palette, background: Color, width: Int) -> String {
        let promptText: String
        if let prompt {
            let buffer = TUIkit.renderToBuffer(prompt, context: RenderContext(availableWidth: 100, availableHeight: 1))
            promptText = buffer.lines.first?.stripped ?? ""
        } else {
            promptText = ""
        }
        let truncated = String(promptText.prefix(width))
        let paddedPrompt = truncated.padding(toLength: width, withPad: " ", startingAt: 0)
        return ANSIRenderer.colorize(paddedPrompt, foreground: palette.foregroundTertiary, background: background)
    }

    // MARK: - Unfocused Text

    /// Builds text content without cursor (unfocused state).
    private func buildTextContent(text: String, palette: any Palette, background: Color, width: Int) -> String {
        let visibleCount = min(text.count, width)
        var displayText = ""
        for i in 0..<visibleCount {
            displayText.append(displayCharacter(i, text))
        }
        let paddedText = displayText.padding(toLength: width, withPad: " ", startingAt: 0)
        let foreground = isDisabled ? palette.foregroundTertiary : palette.foreground
        return ANSIRenderer.colorize(paddedText, foreground: foreground, background: background)
    }

    // MARK: - Focused Text with Cursor

    /// Builds text content with cursor at the specified position (focused state).
    /// Implements horizontal scrolling to keep cursor visible.
    /// Selection is highlighted with accent background if present.
    private func buildTextWithCursor(
        text: String,
        cursorPosition: Int,
        selectionRange: Range<Int>?,
        palette: any Palette,
        cursorStyle: TextCursorStyle,
        cursorTimer: CursorTimer?,
        background: Color,
        width: Int
    ) -> String {
        let clampedPosition = max(0, min(cursorPosition, text.count))

        // Calculate scroll offset to keep cursor visible
        let visibleTextWidth = width - 1  // Reserve 1 char for cursor
        let scrollOffset: Int
        if clampedPosition <= visibleTextWidth {
            scrollOffset = 0
        } else {
            scrollOffset = clampedPosition - visibleTextWidth
        }

        let visibleStart = scrollOffset

        // Compute cursor visibility and color based on animation style
        let (cursorVisible, cursorColor) = computeCursorState(
            baseColor: palette.cursorColor,
            animation: cursorStyle.animation,
            speed: cursorStyle.speed,
            cursorTimer: cursorTimer
        )

        // Build output character by character
        var result = ""
        var outputWidth = 0

        for visibleIndex in 0..<width {
            let textIndex = visibleStart + visibleIndex

            if textIndex == clampedPosition {
                if cursorVisible {
                    let cursorChar = cursorStyle.shape.character
                    result += ANSIRenderer.colorize(String(cursorChar), foreground: cursorColor, background: background)
                } else {
                    // Cursor hidden (blink off): show underlying character or space
                    if textIndex < text.count {
                        let char = displayCharacter(textIndex, text)
                        result += ANSIRenderer.colorize(String(char), foreground: palette.foreground, background: background)
                    } else {
                        result += ANSIRenderer.colorize(" ", foreground: palette.foreground, background: background)
                    }
                }
                outputWidth += 1
            } else if textIndex < text.count && visibleIndex < width - (textIndex >= clampedPosition ? 0 : 1) {
                let char = displayCharacter(textIndex, text)

                // Check if this character is in the selection
                let isSelected = selectionRange.map { textIndex >= $0.lowerBound && textIndex < $0.upperBound } ?? false

                if isSelected {
                    result += ANSIRenderer.colorize(
                        String(char),
                        foreground: palette.background,
                        background: palette.accent.opacity(0.6)
                    )
                } else {
                    result += ANSIRenderer.colorize(String(char), foreground: palette.foreground, background: background)
                }
                outputWidth += 1
            } else if outputWidth < width {
                result += ANSIRenderer.colorize(" ", foreground: palette.foreground, background: background)
                outputWidth += 1
            }

            if outputWidth >= width {
                break
            }
        }

        return result
    }

    // MARK: - Cursor State

    /// Computes the cursor visibility and color based on the animation style and cursor timer.
    private func computeCursorState(
        baseColor: Color,
        animation: TextCursorStyle.Animation,
        speed: TextCursorStyle.Speed,
        cursorTimer: CursorTimer?
    ) -> (visible: Bool, color: Color) {
        switch animation {
        case .none:
            return (true, baseColor)
        case .blink:
            let visible = cursorTimer?.blinkVisible(for: speed) ?? true
            return (visible, baseColor)
        case .pulse:
            let phase = cursorTimer?.pulsePhase(for: speed) ?? 1.0
            let dimColor = baseColor.opacity(0.35)
            let color = Color.lerp(dimColor, baseColor, phase: phase)
            return (true, color)
        }
    }
}
