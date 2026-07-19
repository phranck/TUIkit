import Foundation

/// A dependency-free JSON value used to retain nonvolatile symbol attributes.
public enum CanonicalJSONValue: Codable, Equatable, Hashable, Sendable {
    case array([Self])
    case bool(Bool)
    case double(Double)
    case integer(Int64)
    case null
    case object([String: Self])
    case string(String)
    case unsignedInteger(UInt64)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .integer(value)
        } else if let value = try? container.decode(UInt64.self) {
            self = .unsignedInteger(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([Self].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: Self].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .array(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .integer(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case let .object(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        case let .unsignedInteger(value):
            try container.encode(value)
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(canonicalSortKey)
    }

    var canonicalSortKey: String {
        switch self {
        case let .array(values):
            "a[\(values.map(\.canonicalSortKey).joined(separator: ","))]"
        case let .bool(value):
            "b\(value)"
        case let .double(value):
            "d\(value.bitPattern)"
        case let .integer(value):
            "i\(value)"
        case .null:
            "n"
        case let .object(value):
            "o{\(canonicalSemanticDetailsSortKey(value))}"
        case let .string(value):
            "s\(value.utf8.count):\(value)"
        case let .unsignedInteger(value):
            "u\(value)"
        }
    }
}

func canonicalSemanticDetailsSortKey(
    _ details: [String: CanonicalJSONValue]
) -> String {
    details.keys.sorted().map { key in
        "\(key.utf8.count):\(key)=\(details[key]?.canonicalSortKey ?? "")"
    }.joined(separator: ",")
}
