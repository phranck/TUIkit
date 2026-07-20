//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TerminalStyle.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A normalized terminal color from an SGR foreground or background sequence.
package enum TerminalColor: Sendable, Equatable {
    case ansi(Int)
    case indexed(Int)
    case rgb(red: Int, green: Int, blue: Int)
}

/// The complete visual state applied to one terminal cell.
package struct TerminalStyle: Sendable, Equatable {
    package var isBold = false
    package var isDim = false
    package var isItalic = false
    package var isUnderlined = false
    package var isBlinking = false
    package var isInverted = false
    package var isHidden = false
    package var isStrikethrough = false
    package var foreground: TerminalColor?
    package var background: TerminalColor?

    package init() {}
}

// MARK: - SGR State

extension TerminalStyle {
    package var isDefault: Bool {
        self == Self()
    }

    var paintsBlankCell: Bool {
        background != nil || isInverted || isUnderlined || isStrikethrough
    }

    package var ansiSequence: String {
        let parameters = ansiParameters
        guard !parameters.isEmpty else { return "" }
        return "\u{1B}[\(parameters.map(String.init).joined(separator: ";"))m"
    }

    mutating func apply(sgr parameters: [Int]) {
        var index = 0

        while index < parameters.count {
            let parameter = parameters[index]
            if parameter == 0 {
                self = Self()
            } else if applyEnablingAttribute(parameter) || applyDisablingAttribute(parameter) {
                // Attribute state was updated by the helper.
            } else {
                applyColor(parameter, parameters: parameters, index: &index)
            }
            index += 1
        }
    }
}

// MARK: - SGR Attributes

private extension TerminalStyle {
    mutating func applyEnablingAttribute(_ parameter: Int) -> Bool {
        switch parameter {
        case 1: isBold = true
        case 2: isDim = true
        case 3: isItalic = true
        case 4, 21: isUnderlined = true
        case 5, 6: isBlinking = true
        case 7: isInverted = true
        case 8: isHidden = true
        case 9: isStrikethrough = true
        default: return false
        }
        return true
    }

    mutating func applyDisablingAttribute(_ parameter: Int) -> Bool {
        switch parameter {
        case 22:
            isBold = false
            isDim = false
        case 23: isItalic = false
        case 24: isUnderlined = false
        case 25: isBlinking = false
        case 27: isInverted = false
        case 28: isHidden = false
        case 29: isStrikethrough = false
        default: return false
        }
        return true
    }

    mutating func applyColor(_ parameter: Int, parameters: [Int], index: inout Int) {
        switch parameter {
        case 30...37, 90...97:
            foreground = .ansi(parameter)
        case 38:
            foreground = Self.extendedColor(in: parameters, at: &index) ?? foreground
        case 39:
            foreground = nil
        case 40...47, 100...107:
            background = .ansi(parameter)
        case 48:
            background = Self.extendedColor(in: parameters, at: &index) ?? background
        case 49:
            background = nil
        default:
            break
        }
    }
}

// MARK: - Encoding

private extension TerminalStyle {
    var ansiParameters: [Int] {
        var parameters: [Int] = []

        if isBold { parameters.append(1) }
        if isDim { parameters.append(2) }
        if isItalic { parameters.append(3) }
        if isUnderlined { parameters.append(4) }
        if isBlinking { parameters.append(5) }
        if isInverted { parameters.append(7) }
        if isHidden { parameters.append(8) }
        if isStrikethrough { parameters.append(9) }
        if let foreground {
            parameters.append(contentsOf: Self.parameters(for: foreground, foreground: true))
        }
        if let background {
            parameters.append(contentsOf: Self.parameters(for: background, foreground: false))
        }

        return parameters
    }

    static func extendedColor(in parameters: [Int], at index: inout Int) -> TerminalColor? {
        guard index + 1 < parameters.count else { return nil }

        switch parameters[index + 1] {
        case 5 where index + 2 < parameters.count:
            index += 2
            return .indexed(clampColor(parameters[index]))
        case 2 where index + 4 < parameters.count:
            let red = clampColor(parameters[index + 2])
            let green = clampColor(parameters[index + 3])
            let blue = clampColor(parameters[index + 4])
            index += 4
            return .rgb(red: red, green: green, blue: blue)
        default:
            return nil
        }
    }

    static func parameters(for color: TerminalColor, foreground: Bool) -> [Int] {
        switch color {
        case .ansi(let code):
            return [code]
        case .indexed(let index):
            return [foreground ? 38 : 48, 5, index]
        case .rgb(let red, let green, let blue):
            return [foreground ? 38 : 48, 2, red, green, blue]
        }
    }

    static func clampColor(_ component: Int) -> Int {
        min(255, max(0, component))
    }
}
