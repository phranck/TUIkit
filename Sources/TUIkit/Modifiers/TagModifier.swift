//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TagModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Tagged View

/// A view wrapper that associates a selection value with arbitrary content.
/// Used by List and Picker components to track tagged rows.
public struct Tagged<Value: Hashable, Content: View>: View {
    /// The tag value associated with this view.
    let tagValue: Value
    
    /// The wrapped content view.
    let content: Content
    
    /// Creates a tagged view.
    ///
    /// - Parameters:
    ///   - value: The value to associate with this view.
    ///   - content: The view being tagged.
    public init(value: Value, @ViewBuilder content: () -> Content) {
        self.tagValue = value
        self.content = content()
    }
    
    public var body: Never {
        fatalError("Tagged renders via Renderable")
    }
}

// MARK: - Tagged Rendering

extension Tagged: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Just render the content; the tag value is handled by parent List
        return TUIkit.renderToBuffer(content, context: context)
    }
}

// MARK: - View Extension

extension View {
    /// Tags this view with a value for selection in List or Picker components.
    ///
    /// - Parameter value: The value to associate with this view.
    /// - Returns: A tagged view wrapper.
    public func tag<V: Hashable>(_ value: V) -> Tagged<V, Self> {
        Tagged(value: value) { self }
    }
}
