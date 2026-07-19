import Foundation

public struct LoadedSymbolGraph: Equatable, Sendable {
    public let moduleName: String
    public let sourceFiles: [String]
    public let symbols: [LoadedSymbol]
    public let relationships: [LoadedRelationship]
    public let excludedSynthesizedSymbolIDs: [String]

    public init(
        moduleName: String,
        sourceFiles: [String],
        symbols: [LoadedSymbol],
        relationships: [LoadedRelationship],
        excludedSynthesizedSymbolIDs: [String] = []
    ) {
        self.moduleName = moduleName
        self.sourceFiles = sourceFiles
        self.symbols = symbols
        self.relationships = relationships
        self.excludedSynthesizedSymbolIDs = excludedSynthesizedSymbolIDs
    }
}

public enum ExtensionProvenanceMode: Equatable, Sendable {
    case disabled
    case strict
}

public struct LoadedSymbol: Equatable, Sendable {
    public let preciseIdentifier: String
    public let kindIdentifier: String
    public let title: String
    public let pathComponents: [String]
    public let declarationFragments: [LoadedDeclarationFragment]
    public let accessLevel: String
    public let semanticDetails: [String: CanonicalJSONValue]
    public let sourceFile: String
}

public struct LoadedDeclarationFragment: Equatable, Sendable {
    public let kind: String
    public let spelling: String
    public let preciseIdentifier: String?
}

public struct LoadedRelationship: Equatable, Sendable {
    public let kind: String
    public let source: String
    public let target: String
    public let targetFallback: String?
    public let semanticDetails: [String: CanonicalJSONValue]
    public let sourceFile: String

    public init(
        kind: String,
        source: String,
        target: String,
        targetFallback: String?,
        semanticDetails: [String: CanonicalJSONValue] = [:],
        sourceFile: String
    ) {
        self.kind = kind
        self.source = source
        self.target = target
        self.targetFallback = targetFallback
        self.semanticDetails = semanticDetails
        self.sourceFile = sourceFile
    }
}

struct RawSymbolGraph: Decodable {
    let module: RawModule
    let symbols: [RawSymbol]
    let relationships: [RawRelationship]
}

struct RawModule: Decodable {
    let name: String
}

struct RawSymbol: Decodable {
    let kind: RawKind
    let identifier: RawIdentifier
    let pathComponents: [String]
    let names: RawNames?
    let declarationFragments: [RawDeclarationFragment]
    let accessLevel: String
    let semanticDetails: [String: CanonicalJSONValue]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self.kind = try container.decode(RawKind.self, forKey: .key("kind"))
        self.identifier = try container.decode(RawIdentifier.self, forKey: .key("identifier"))
        self.pathComponents = try container.decode([String].self, forKey: .key("pathComponents"))
        self.names = try container.decodeIfPresent(RawNames.self, forKey: .key("names"))
        self.declarationFragments = try container.decode(
            [RawDeclarationFragment].self,
            forKey: .key("declarationFragments")
        )
        self.accessLevel = try container.decode(String.self, forKey: .key("accessLevel"))

        let ignoredKeys: Set<String> = [
            "accessLevel",
            "declarationFragments",
            "docComment",
            "identifier",
            "kind",
            "location",
            "names",
            "pathComponents",
        ]
        var details: [String: CanonicalJSONValue] = [:]
        for key in container.allKeys where !ignoredKeys.contains(key.stringValue) {
            details[key.stringValue] = try container.decode(CanonicalJSONValue.self, forKey: key)
        }
        self.semanticDetails = details
    }
}

struct RawKind: Decodable {
    let identifier: String
}

struct RawIdentifier: Decodable {
    let precise: String
}

struct RawNames: Decodable {
    let title: String?
}

struct RawDeclarationFragment: Decodable {
    let kind: String
    let spelling: String
    let preciseIdentifier: String?
}

struct RawRelationship: Decodable {
    let kind: String
    let source: String
    let target: String
    let targetFallback: String?
    let semanticDetails: [String: CanonicalJSONValue]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self.kind = try container.decode(String.self, forKey: .key("kind"))
        self.source = try container.decode(String.self, forKey: .key("source"))
        self.target = try container.decode(String.self, forKey: .key("target"))
        self.targetFallback = try container.decodeIfPresent(
            String.self,
            forKey: .key("targetFallback")
        )

        let knownKeys: Set<String> = ["kind", "source", "target", "targetFallback"]
        var details: [String: CanonicalJSONValue] = [:]
        for key in container.allKeys where !knownKeys.contains(key.stringValue) {
            details[key.stringValue] = try container.decode(CanonicalJSONValue.self, forKey: key)
        }
        self.semanticDetails = details
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    static func key(_ value: String) -> Self {
        Self(stringValue: value)!
    }
}
