//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StoragePersistenceError.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Storage Persistence Error

/// Describes one failed attempt to persist application storage.
///
/// Reasons are sanitized: they identify the failing step and the underlying
/// error's domain and code, but never include file paths or stored content,
/// so the error can be logged or surfaced without leaking user data.
public struct StoragePersistenceError: Error, Sendable, CustomStringConvertible {
    /// The persistence step that failed.
    public enum Operation: String, Sendable {
        /// Encoding a value into its JSON representation failed.
        case encode

        /// Serializing the snapshot dictionary into a payload failed.
        case serialize

        /// Writing the serialized payload to its destination failed.
        case write
    }

    /// The failing persistence step.
    public let operation: Operation

    /// Sanitized failure reason without paths or stored content.
    public let reason: String

    /// Creates an error from a failing step and its underlying error.
    ///
    /// The underlying error is reduced to its domain and code. Foundation
    /// errors carry file paths in their descriptions and user info, so the
    /// original error is deliberately not retained.
    ///
    /// - Parameters:
    ///   - operation: The persistence step that failed.
    ///   - underlying: The error thrown by that step.
    init(operation: Operation, underlying: any Error) {
        self.operation = operation
        let nsError = underlying as NSError
        self.reason = "\(nsError.domain) code \(nsError.code)"
    }

    public var description: String {
        "Application storage \(operation.rawValue) failed: \(reason)"
    }
}
