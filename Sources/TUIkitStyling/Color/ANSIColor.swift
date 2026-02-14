//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ANSIColor.swift
//
//  Created by LAYERED.work
//  License: MIT

/// The 8 standard ANSI colors.
public enum ANSIColor: UInt8, Sendable {
    case black = 0
    case red = 1
    case green = 2
    case yellow = 3
    case blue = 4
    case magenta = 5
    case cyan = 6
    case white = 7
    case `default` = 9

    /// The ANSI code for foreground color (30-37, 39 for default).
    public var foregroundCode: UInt8 {
        30 + rawValue
    }

    /// The ANSI code for background color (40-47, 49 for default).
    public var backgroundCode: UInt8 {
        40 + rawValue
    }

    /// The ANSI code for bright foreground color (90-97).
    public var brightForegroundCode: UInt8 {
        90 + rawValue
    }

    /// The ANSI code for bright background color (100-107).
    public var brightBackgroundCode: UInt8 {
        100 + rawValue
    }

    // MARK: - xterm Standard RGB Values

    /// The standard RGB values for this ANSI color (xterm defaults).
    public var rgbValues: (red: UInt8, green: UInt8, blue: UInt8) {
        switch self {
        case .black:   return (0, 0, 0)
        case .red:     return (205, 0, 0)
        case .green:   return (0, 205, 0)
        case .yellow:  return (205, 205, 0)
        case .blue:    return (0, 0, 238)
        case .magenta: return (205, 0, 205)
        case .cyan:    return (0, 205, 205)
        case .white:   return (229, 229, 229)
        case .default: return (229, 229, 229)
        }
    }

    /// The bright RGB values for this ANSI color (xterm defaults).
    public var brightRGBValues: (red: UInt8, green: UInt8, blue: UInt8) {
        switch self {
        case .black:   return (127, 127, 127)
        case .red:     return (255, 0, 0)
        case .green:   return (0, 255, 0)
        case .yellow:  return (255, 255, 0)
        case .blue:    return (92, 92, 255)
        case .magenta: return (255, 0, 255)
        case .cyan:    return (0, 255, 255)
        case .white:   return (255, 255, 255)
        case .default: return (255, 255, 255)
        }
    }
}
