//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RuntimeDiagnostics.swift
//
//  License: MIT

import Foundation

/// A deterministic framework diagnostic tied to a render-tree identity.
struct RuntimeDiagnostic: Hashable, Sendable, CustomStringConvertible {
    let identity: ViewIdentity
    let message: String

    var description: String {
        "\(message) at \(identity.path)"
    }
}

/// Per-runtime diagnostic collector with optional output reporting.
final class RuntimeDiagnostics: @unchecked Sendable {
    private struct State: Sendable {
        var seen: Set<RuntimeDiagnostic> = []
        var current: [RuntimeDiagnostic] = []
    }

    private let state = Lock(initialState: State())
    private let reporter: (@Sendable (RuntimeDiagnostic) -> Void)?

    init(reporter: (@Sendable (RuntimeDiagnostic) -> Void)? = nil) {
        self.reporter = reporter
    }

    var messages: [String] {
        state.withLock { $0.current.map(\.description) }
    }

    func beginRenderPass() {
        state.withLock { diagnostics in
            diagnostics.seen.removeAll(keepingCapacity: true)
            diagnostics.current.removeAll(keepingCapacity: true)
        }
    }

    func emit(_ diagnostic: RuntimeDiagnostic) {
        let shouldReport = state.withLock { diagnostics -> Bool in
            guard diagnostics.seen.insert(diagnostic).inserted else { return false }
            diagnostics.current.append(diagnostic)
            return true
        }

        if shouldReport {
            reporter?(diagnostic)
        }
    }

    func reset() {
        beginRenderPass()
    }

    static func standardError() -> RuntimeDiagnostics {
        RuntimeDiagnostics { diagnostic in
            let line = "TUIkit warning: \(diagnostic.description)\n"
            FileHandle.standardError.write(Data(line.utf8))
        }
    }
}
