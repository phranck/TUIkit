/// A stable, machine-readable diagnostic emitted by the API compatibility tools.
public struct APICheckDiagnostic: Error, Equatable, Sendable, CustomStringConvertible {
    public let code: String
    public let message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }

    public var description: String {
        "error[\(code)]: \(message)"
    }
}

extension APICheckDiagnostic: Comparable {
    public static func < (lhs: APICheckDiagnostic, rhs: APICheckDiagnostic) -> Bool {
        if lhs.code != rhs.code {
            return lhs.code < rhs.code
        }
        return lhs.message < rhs.message
    }
}
