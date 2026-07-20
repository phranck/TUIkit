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

    /// Maps one source grapheme to its displayed grapheme.
    /// For TextField: the original character. For SecureField: a bullet.
    let displayCharacter: (_ character: Character) -> Character

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
        let sanitizedText = text.sanitizedForTerminal
        let isEmpty = sanitizedText.isEmpty
        let backgroundColor = palette.accent.opacity(ViewConstants.focusBorderDim)

        if isEmpty && !isFocused && prompt != nil {
            return buildPromptContent(palette: palette, background: backgroundColor, width: contentWidth)
        } else if isFocused {
            return buildTextWithCursor(
                text: sanitizedText,
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
                text: sanitizedText,
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
        let truncated = promptText.ansiAwarePrefix(visibleCount: width)
        let paddedPrompt = truncated.padToVisibleWidth(width)
        return ANSIRenderer.colorize(paddedPrompt, foreground: palette.foregroundTertiary, background: background)
    }

    // MARK: - Unfocused Text

    /// Builds text content without cursor (unfocused state).
    private func buildTextContent(text: String, palette: any Palette, background: Color, width: Int) -> String {
        let characters = displayCharacters(for: text)
        var displayText = ""
        var displayWidth = 0

        for character in characters {
            let characterWidth = character.terminalWidth
            guard displayWidth + characterWidth <= width else { break }
            displayText.append(character)
            displayWidth += characterWidth
        }

        let paddedText = displayText.padToVisibleWidth(width)
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
        let characters = displayCharacters(for: text)
        let clampedPosition = max(0, min(cursorPosition, characters.count))
        let visibleStart = visibleStart(
            characters: characters,
            cursorPosition: clampedPosition,
            availableWidth: max(0, width - 1)
        )

        // Compute cursor visibility and color based on animation style
        let (cursorVisible, cursorColor) = computeCursorState(
            baseColor: palette.cursorColor,
            animation: cursorStyle.animation,
            speed: cursorStyle.speed,
            cursorTimer: cursorTimer
        )

        // Build output one complete grapheme at a time.
        var result = ""
        var outputWidth = 0
        var textIndex = visibleStart
        var cursorRendered = false

        while outputWidth < width {
            if !cursorRendered && textIndex == clampedPosition {
                if cursorVisible {
                    let cursorChar = cursorStyle.shape.character
                    result += ANSIRenderer.colorize(String(cursorChar), foreground: cursorColor, background: background)
                } else {
                    // Cursor hidden (blink off): show underlying character or space
                    if textIndex < characters.count {
                        let char = characters[textIndex]
                        result += ANSIRenderer.colorize(String(char), foreground: palette.foreground, background: background)
                    } else {
                        result += ANSIRenderer.colorize(" ", foreground: palette.foreground, background: background)
                    }
                }
                outputWidth += 1
                cursorRendered = true
                if textIndex < characters.count {
                    textIndex += 1
                }
            } else if textIndex < characters.count {
                let char = characters[textIndex]
                let characterWidth = char.terminalWidth
                guard outputWidth + characterWidth <= width else { break }

                // Check if this character is in the selection
                let isSelected = selectionRange.map { textIndex >= $0.lowerBound && textIndex < $0.upperBound } ?? false

                if isSelected {
                    result += ANSIRenderer.colorize(
                        String(char),
                        foreground: palette.background,
                        background: palette.accent.opacity(ViewConstants.selectionIndicator)
                    )
                } else {
                    result += ANSIRenderer.colorize(String(char), foreground: palette.foreground, background: background)
                }
                outputWidth += characterWidth
                textIndex += 1
            } else {
                result += ANSIRenderer.colorize(" ", foreground: palette.foreground, background: background)
                outputWidth += 1
            }
        }

        if outputWidth < width {
            let padding = String(repeating: " ", count: width - outputWidth)
            result += ANSIRenderer.colorize(padding, foreground: palette.foreground, background: background)
        }

        return result
    }

    private func displayCharacters(for text: String) -> [Character] {
        text.map(displayCharacter)
    }

    private func visibleStart(
        characters: [Character],
        cursorPosition: Int,
        availableWidth: Int
    ) -> Int {
        var start = cursorPosition
        var usedWidth = 0

        while start > 0 {
            let characterWidth = characters[start - 1].terminalWidth
            guard usedWidth + characterWidth <= availableWidth else { break }
            usedWidth += characterWidth
            start -= 1
        }

        return start
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
            let dimColor = baseColor.opacity(ViewConstants.focusPulseMin)
            let color = Color.lerp(dimColor, baseColor, phase: phase)
            return (true, color)
        }
    }
}
