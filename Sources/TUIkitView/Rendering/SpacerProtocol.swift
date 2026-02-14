//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SpacerProtocol.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A protocol for views that act as flexible spacers in layout containers.
///
/// This protocol decouples the layout system from the concrete `Spacer` type,
/// allowing `ChildView` and `ChildInfo` to detect spacer behavior without
/// depending on a specific view type.
///
/// The concrete `Spacer` view conforms to this protocol.
@MainActor
public protocol SpacerProtocol {
    /// The minimum length of the spacer (in characters/lines).
    ///
    /// If nil, the spacer expands as much as possible.
    var spacerMinLength: Int? { get }
}
