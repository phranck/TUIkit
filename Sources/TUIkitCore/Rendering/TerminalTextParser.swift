//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TerminalTextParser.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A parsed unit from text that may contain terminal escape sequences.
enum TerminalTextToken {
    /// A printable extended grapheme cluster.
    case grapheme(Character)

    /// A line-feed boundary retained for multiline text layout.
    case lineBreak

    /// A supported Select Graphic Rendition sequence.
    case sgr(parameters: [Int], sequence: String)
}

/// Parses printable graphemes and trusted SGR state at a terminal boundary.
///
/// Cursor movement, OSC, DCS, APC, PM, SOS, C0, and C1 controls are consumed
/// without becoming output. This keeps measurement and rendering on the same
/// sanitized stream and prevents embedded terminal commands from surviving.
enum TerminalTextParser {
    static func scan(
        _ text: String,
        preservingLineBreaks: Bool = false,
        body: (TerminalTextToken) -> Void
    ) {
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            if character.isLineBreakCluster {
                if preservingLineBreaks {
                    body(.lineBreak)
                }
                index = text.index(after: index)
                continue
            }

            guard let scalarValue = character.singleScalarValue else {
                if !character.containsTerminalControl {
                    body(.grapheme(character))
                }
                index = text.index(after: index)
                continue
            }

            switch scalarValue {
            case 0x1B:
                let result = consumeEscape(in: text, from: index)
                if let sgr = result.sgr {
                    body(.sgr(parameters: sgr, sequence: String(text[index..<result.endIndex])))
                }
                index = result.endIndex
            case 0x9B:
                let result = consumeCSI(in: text, after: text.index(after: index))
                if let sgr = result.sgr {
                    body(.sgr(parameters: sgr, sequence: String(text[index..<result.endIndex])))
                }
                index = result.endIndex
            case 0x90, 0x98, 0x9D, 0x9E, 0x9F:
                index = consumeControlString(
                    in: text,
                    after: text.index(after: index),
                    allowsBellTerminator: scalarValue == 0x9D
                )
            case 0x00...0x1F, 0x7F...0x9F:
                index = text.index(after: index)
            default:
                body(.grapheme(character))
                index = text.index(after: index)
            }
        }
    }
}

// MARK: - Escape Parsing

private extension TerminalTextParser {
    struct ParseResult {
        let endIndex: String.Index
        let sgr: [Int]?
    }

    static func consumeEscape(in text: String, from escapeIndex: String.Index) -> ParseResult {
        let nextIndex = text.index(after: escapeIndex)
        guard nextIndex < text.endIndex, let introducer = text[nextIndex].singleScalarValue else {
            return ParseResult(endIndex: text.endIndex, sgr: nil)
        }

        switch introducer {
        case 0x5B:
            return consumeCSI(in: text, after: text.index(after: nextIndex))
        case 0x50, 0x58, 0x5E, 0x5F:
            let endIndex = consumeControlString(
                in: text,
                after: text.index(after: nextIndex),
                allowsBellTerminator: false
            )
            return ParseResult(endIndex: endIndex, sgr: nil)
        case 0x5D:
            let endIndex = consumeControlString(
                in: text,
                after: text.index(after: nextIndex),
                allowsBellTerminator: true
            )
            return ParseResult(endIndex: endIndex, sgr: nil)
        default:
            return ParseResult(endIndex: consumeEscapeCommand(in: text, after: nextIndex), sgr: nil)
        }
    }

    static func consumeCSI(in text: String, after introducer: String.Index) -> ParseResult {
        var index = introducer
        var finalValue: UInt32?
        var finalIndex = text.endIndex

        while index < text.endIndex {
            guard let value = text[index].singleScalarValue else {
                return ParseResult(endIndex: text.index(after: index), sgr: nil)
            }

            if (0x40...0x7E).contains(value) {
                finalValue = value
                finalIndex = index
                index = text.index(after: index)
                break
            }

            guard (0x20...0x3F).contains(value) else {
                return ParseResult(endIndex: text.index(after: index), sgr: nil)
            }
            index = text.index(after: index)
        }

        guard finalValue == 0x6D else {
            return ParseResult(endIndex: index, sgr: nil)
        }

        let rawParameters = text[introducer..<finalIndex]
        guard rawParameters.allSatisfy({ character in
            guard let value = character.singleScalarValue else { return false }
            return (0x30...0x39).contains(value) || value == 0x3B
        }) else {
            return ParseResult(endIndex: index, sgr: nil)
        }

        let parameters: [Int]
        if rawParameters.isEmpty {
            parameters = [0]
        } else {
            parameters = rawParameters.split(separator: ";", omittingEmptySubsequences: false).map {
                Int($0) ?? 0
            }
        }
        return ParseResult(endIndex: index, sgr: parameters)
    }

    static func consumeControlString(
        in text: String,
        after introducer: String.Index,
        allowsBellTerminator: Bool
    ) -> String.Index {
        var index = introducer

        while index < text.endIndex {
            guard let value = text[index].singleScalarValue else {
                index = text.index(after: index)
                continue
            }

            if allowsBellTerminator && value == 0x07 {
                return text.index(after: index)
            }
            if value == 0x9C {
                return text.index(after: index)
            }
            if value == 0x1B {
                let nextIndex = text.index(after: index)
                if nextIndex < text.endIndex && text[nextIndex].singleScalarValue == 0x5C {
                    return text.index(after: nextIndex)
                }
            }
            index = text.index(after: index)
        }

        return text.endIndex
    }

    static func consumeEscapeCommand(in text: String, after escapeIndex: String.Index) -> String.Index {
        var index = escapeIndex

        while index < text.endIndex {
            guard let value = text[index].singleScalarValue else {
                return text.index(after: index)
            }
            index = text.index(after: index)

            if (0x30...0x7E).contains(value) {
                return index
            }
            guard (0x20...0x2F).contains(value) else {
                return index
            }
        }

        return text.endIndex
    }
}

private extension Character {
    var isLineBreakCluster: Bool {
        let scalars = unicodeScalars.map(\.value)
        return scalars.contains(0x0A) && scalars.allSatisfy { $0 == 0x0A || $0 == 0x0D }
    }

    var containsTerminalControl: Bool {
        unicodeScalars.contains { scalar in
            let value = scalar.value
            return (0x00...0x1F).contains(value) || (0x7F...0x9F).contains(value)
        }
    }

    var singleScalarValue: UInt32? {
        guard unicodeScalars.count == 1 else { return nil }
        return unicodeScalars.first?.value
    }
}
