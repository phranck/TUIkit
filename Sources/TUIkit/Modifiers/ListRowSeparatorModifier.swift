//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ListRowSeparatorModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

/// Tracks whether the listRowSeparator warning has been logged.
@MainActor
private var listRowSeparatorWarningLogged = false

/// A stub modifier for list row separators.
///
/// This modifier exists for SwiftUI API compatibility but has no visual effect
/// in TUIkit. Terminal-based UIs do not support the fine-grained separator
/// styling that SwiftUI provides.
///
/// A warning is logged when this modifier is used.
public struct ListRowSeparatorModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// The visibility of the separator.
    let visibility: Visibility

    /// The edges to apply the separator to.
    let edges: VerticalEdge.Set

    public var body: Never {
        fatalError("ListRowSeparatorModifier renders via Renderable")
    }
}

// MARK: - Visibility

/// Visibility options for list row separators.
///
/// Matches SwiftUI's Visibility enum for API compatibility.
public enum Visibility: Sendable {
    /// The separator is automatically shown or hidden based on context.
    case automatic

    /// The separator is always visible.
    case visible

    /// The separator is always hidden.
    case hidden
}

// MARK: - Vertical Edge Set

/// A set of vertical edges (top and/or bottom).
///
/// Used for specifying which edges of a list row should have separators.
public enum VerticalEdge: Sendable {
    /// The top edge.
    case top

    /// The bottom edge.
    case bottom

    /// A set of vertical edges.
    public struct Set: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// The top edge only.
        public static let top = Self(rawValue: 1 << 0)

        /// The bottom edge only.
        public static let bottom = Self(rawValue: 1 << 1)

        /// All edges (top and bottom).
        public static let all: Set = [.top, .bottom]
    }
}

// MARK: - Equatable

extension ListRowSeparatorModifier: Equatable where Content: Equatable {
    nonisolated public static func == (lhs: ListRowSeparatorModifier<Content>, rhs: ListRowSeparatorModifier<Content>) -> Bool {
        MainActor.assumeIsolated {
            lhs.content == rhs.content &&
            lhs.visibility == rhs.visibility &&
            lhs.edges == rhs.edges
        }
    }
}

extension Visibility: Equatable {}

// MARK: - Renderable

extension ListRowSeparatorModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Log warning once per session.
        if !listRowSeparatorWarningLogged {
            listRowSeparatorWarningLogged = true
            // Use stderr to avoid interfering with terminal UI.
            fputs("TUIkit warning: .listRowSeparator() has no effect. Separators are not supported in terminal UIs.\n", stderr)
        }

        // Return content unchanged.
        return TUIkit.renderToBuffer(content, context: context)
    }
}
