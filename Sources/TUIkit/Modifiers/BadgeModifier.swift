//  🖥️ TUIKit — Terminal UI Kit for Swift
//  BadgeModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A modifier that displays a decorative badge on a view.
///
/// Badges are typically used with List rows to show counts, status,
/// or other labels. The badge is rendered right-aligned and styled
/// with a dimmed foreground color.
///
/// The badge value is stored in the environment and propagates to
/// child views. Badges automatically hide when:
/// - The count is 0 (for integer badges)
/// - The label is nil (for optional Text/String badges)
public struct BadgeModifier<Content: View>: View {
    /// The content to apply the badge to.
    let content: Content

    /// The badge value (Int, Text, or String).
    let value: BadgeValue

    public var body: Never {
        fatalError("BadgeModifier renders via Renderable")
    }
}

// MARK: - Badge Value

/// Represents a badge value that can be Int or String.
public enum BadgeValue: Sendable {
    /// An integer badge (0 hides the badge).
    case int(Int)

    /// A String badge (nil hides the badge).
    case string(String?)

    /// Returns true if the badge should be hidden.
    public var isHidden: Bool {
        switch self {
        case .int(let intValue):
            return intValue == 0
        case .string(let string):
            return string == nil || string?.isEmpty == true
        }
    }

    /// Returns the display text for the badge.
    public var displayText: String {
        switch self {
        case .int(let intValue):
            return "\(intValue)"
        case .string(let string):
            return string ?? ""
        }
    }
}

// MARK: - Equatable

extension BadgeModifier: @preconcurrency Equatable where Content: Equatable {
    public static func == (lhs: BadgeModifier<Content>, rhs: BadgeModifier<Content>) -> Bool {
        lhs.content == rhs.content && lhs.value == rhs.value
    }
}

extension BadgeValue: Equatable {
    public static func == (lhs: BadgeValue, rhs: BadgeValue) -> Bool {
        switch (lhs, rhs) {
        case (.int(let a), .int(let b)):
            return a == b
        case (.string(let a), .string(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Badge Extraction

/// Extracts the badge value from a view if it's wrapped in a BadgeModifier.
///
/// This is used by List to extract badge values during row extraction.
@MainActor
public func extractBadgeValue<V: View>(from view: V) -> BadgeValue? {
    // Use Mirror to check if the view is a BadgeModifier
    let mirror = Mirror(reflecting: view)
    for child in mirror.children {
        if child.label == "value", let badge = child.value as? BadgeValue {
            return badge
        }
    }
    return nil
}

// MARK: - Renderable

extension BadgeModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Create modified environment with badge value.
        let modifiedEnvironment = context.environment.setting(\EnvironmentValues.badgeValue, to: value)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)

        // Render content with the badge in environment.
        return TUIkit.renderToBuffer(content, context: modifiedContext)
    }
}
