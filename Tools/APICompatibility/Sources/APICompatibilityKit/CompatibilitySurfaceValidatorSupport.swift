import Foundation

struct SurfaceNormalizer {
    private let identifierMap: [String: String]
    private let moduleNames: [String]

    init(manifest: CompatibilityManifest, moduleNames: [String]) {
        let tuikitByID = Dictionary(grouping: manifest.tuikitDecisions, by: \.symbolID)
        var map: [String: String] = [:]
        for (index, decision) in manifest.decisions.sorted(by: { $0.referenceID < $1.referenceID }).enumerated() {
            guard let tuikitID = decision.tuikitSymbolID,
                  tuikitByID[tuikitID]?.contains(where: { $0.referenceID == decision.referenceID }) == true
            else { continue }
            let token = "$MAPPED[\(index)]"
            map[decision.referenceID] = token
            map[tuikitID] = token
        }
        identifierMap = map
        self.moduleNames = Set(moduleNames).sorted {
            $0.count == $1.count ? $0 < $1 : $0.count > $1.count
        }
    }

    func surface(
        symbol: CanonicalSymbol,
        relationships: [CanonicalRelationship]
    ) -> SymbolCompatibilitySurface {
        let semantics = semanticBuckets(symbol.semanticDetails)
        let fragments = symbol.declarationFragments.map(normalize)
        let normalizedRelationships = relationships.map(normalize).sorted(by: relationshipOrder)
        return SymbolCompatibilitySurface(
            kind: normalizeText(symbol.kindIdentifier),
            declaration: DeclarationSurface(
                access: normalizeText(symbol.accessLevel),
                title: normalizeText(symbol.title),
                path: symbol.pathComponents.map(normalizeText),
                canonical: fragments.map(\.spelling).joined()
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                fragments: fragments,
                semantics: semantics.declaration
            ),
            generics: semantics.generics,
            availability: semantics.availability,
            isolation: semantics.isolation,
            sendability: SendabilitySurface(
                semantics: semantics.sendability,
                relationships: normalizedRelationships.filter(\.isSendable)
            ),
            relationships: normalizedRelationships.filter { !$0.isSendable }
        )
    }

    func collisionKey(for symbol: CanonicalSymbol) -> CollisionKey {
        CollisionKey(
            title: normalizeText(symbol.title),
            path: symbol.pathComponents.map(normalizeText)
        )
    }

    private func semanticBuckets(
        _ details: [String: CanonicalJSONValue]
    ) -> SemanticBuckets {
        var buckets = SemanticBuckets()
        for (key, value) in details {
            let entry = NormalizedSemanticEntry(key: normalizeText(key), value: normalize(value))
            let lower = key.lowercased()
            if lower.contains("availab") {
                buckets.availability.append(entry)
            } else if lower.contains("isolat") || lower.contains("actor") {
                buckets.isolation.append(entry)
            } else if lower.contains("generic") || lower.contains("constraint") || lower.contains("requirement") {
                buckets.generics.append(entry)
            } else if lower.contains("sendable") || lower.contains("sending")
                || (lower.contains("conform") && value.containsSendable) {
                buckets.sendability.append(entry)
            } else {
                buckets.declaration.append(entry)
            }
        }
        buckets.sort()
        return buckets
    }

    private func normalize(_ relationship: CanonicalRelationship) -> NormalizedRelationship {
        NormalizedRelationship(
            kind: normalizeText(relationship.kind),
            source: normalizeIdentifier(relationship.source),
            target: normalizeIdentifier(relationship.target),
            targetFallback: relationship.targetFallback.map(normalizeQualifiedName),
            semanticDetails: relationship.semanticDetails.map {
                NormalizedSemanticEntry(
                    key: normalizeText($0.key),
                    value: normalize($0.value)
                )
            }.sorted(by: semanticEntryOrder)
        )
    }

    private func normalize(
        _ fragment: CanonicalDeclarationFragment
    ) -> NormalizedFragment {
        NormalizedFragment(
            kind: normalizeText(fragment.kind),
            spelling: fragment.kind == "typeIdentifier"
                ? normalizeQualifiedName(fragment.spelling)
                : fragment.spelling,
            preciseIdentifier: fragment.preciseIdentifier.map(normalizeIdentifier)
        )
    }

    private func normalize(_ value: CanonicalJSONValue) -> NormalizedJSONValue {
        switch value {
        case let .array(values):
            return .array(values.map(normalize))
        case let .bool(value):
            return .bool(value)
        case let .double(value):
            return .double(value)
        case let .integer(value):
            return .integer(value)
        case .null:
            return .null
        case let .object(value):
            return .object(normalizeObject(value))
        case let .string(value):
            return .string(normalizeText(value))
        case let .unsignedInteger(value):
            return .unsignedInteger(value)
        }
    }

    private func normalizeIdentifier(_ value: String) -> String {
        identifierMap[value] ?? value
    }

    private func normalizeObject(
        _ value: [String: CanonicalJSONValue]
    ) -> [NormalizedJSONEntry] {
        let fragmentKind: String?
        if case let .string(kind)? = value["kind"] {
            fragmentKind = kind
        } else {
            fragmentKind = nil
        }
        return value.map { key, entryValue in
            let normalizedValue: NormalizedJSONValue
            if key == "spelling",
               fragmentKind == "typeIdentifier",
               case let .string(spelling) = entryValue {
                normalizedValue = .string(normalizeQualifiedName(spelling))
            } else if key.lowercased().contains("module"),
                      case let .string(moduleName) = entryValue {
                normalizedValue = .string(normalizeModuleName(moduleName))
            } else {
                normalizedValue = normalize(entryValue)
            }
            return NormalizedJSONEntry(key: key, value: normalizedValue)
        }.sorted(by: jsonEntryOrder)
    }

    private func normalizeText(_ value: String) -> String {
        identifierMap[value] ?? value
    }

    private func normalizeQualifiedName(_ value: String) -> String {
        for moduleName in moduleNames {
            if value == moduleName {
                return "$MODULE"
            }
            if value.hasPrefix("\(moduleName).") {
                return "$MODULE\(value.dropFirst(moduleName.count))"
            }
        }
        return value
    }

    private func normalizeModuleName(_ value: String) -> String {
        moduleNames.contains(value) ? "$MODULE" : value
    }
}

struct SurfaceOccurrence {
    let source: SnapshotSourceIdentity
    let surface: SymbolCompatibilitySurface
}

struct SnapshotSourceIdentity: Hashable {
    let id: String
    let moduleName: String
    let platform: String
    let targetTriple: String
    let sdkName: String
    let sdkVersion: String
    let sdkBuild: String
    let compilerVersion: String

    init(_ source: APISnapshotSetSourceDescriptor) {
        self.id = source.id
        self.moduleName = source.moduleName
        self.platform = source.platform
        self.targetTriple = source.targetTriple
        self.sdkName = source.sdkName
        self.sdkVersion = source.sdkVersion
        self.sdkBuild = source.sdkBuild
        self.compilerVersion = source.compilerVersion
    }

    var diagnosticLabel: String {
        "\(id) (\(moduleName)/\(platform))"
    }
}

struct SurfaceMismatch {
    let difference: CompatibilityDifference
    let reference: SnapshotSourceIdentity
    let current: SnapshotSourceIdentity
}

struct CollisionOccurrence {
    let sourceID: String
    let symbolID: String
    let key: CollisionKey
}

struct CollisionKey: Hashable {
    let title: String
    let path: [String]
}

struct SymbolCompatibilitySurface: Hashable {
    let kind: String
    let declaration: DeclarationSurface
    let generics: [NormalizedSemanticEntry]
    let availability: [NormalizedSemanticEntry]
    let isolation: [NormalizedSemanticEntry]
    let sendability: SendabilitySurface
    let relationships: [NormalizedRelationship]

    func value(for difference: CompatibilityDifference) -> SurfaceDimensionValue {
        switch difference {
        case .availability: .availability(availability)
        case .declaration: .declaration(declaration)
        case .generics: .generics(generics)
        case .isolation: .isolation(isolation)
        case .kind: .kind(kind)
        case .relationships: .relationships(relationships)
        case .sendability: .sendability(sendability)
        }
    }
}

enum SurfaceDimensionValue: Hashable {
    case availability([NormalizedSemanticEntry])
    case declaration(DeclarationSurface)
    case generics([NormalizedSemanticEntry])
    case isolation([NormalizedSemanticEntry])
    case kind(String)
    case relationships([NormalizedRelationship])
    case sendability(SendabilitySurface)
}

struct DeclarationSurface: Hashable {
    let access: String
    let title: String
    let path: [String]
    let canonical: String
    let fragments: [NormalizedFragment]
    let semantics: [NormalizedSemanticEntry]
}

struct NormalizedFragment: Hashable {
    let kind: String
    let spelling: String
    let preciseIdentifier: String?
}

struct NormalizedSemanticEntry: Hashable {
    let key: String
    let value: NormalizedJSONValue
}

struct SendabilitySurface: Hashable {
    let semantics: [NormalizedSemanticEntry]
    let relationships: [NormalizedRelationship]
}

struct NormalizedRelationship: Hashable {
    let kind: String
    let source: String
    let target: String
    let targetFallback: String?
    let semanticDetails: [NormalizedSemanticEntry]

    var isSendable: Bool {
        kind.lowercased().contains("conform")
            && (Self.sendabilityIdentifiers.contains(target)
                || targetFallback.map(Self.sendabilityIdentifiers.contains) == true)
    }

    private static let sendabilityIdentifiers: Set<String> = [
        "Sendable",
        "SendableMetatype",
        "Swift.Sendable",
        "Swift.SendableMetatype",
        "s:s8SendableP",
        "s:s16SendableMetatypeP",
    ]
}

struct SemanticBuckets {
    var declaration: [NormalizedSemanticEntry] = []
    var generics: [NormalizedSemanticEntry] = []
    var availability: [NormalizedSemanticEntry] = []
    var isolation: [NormalizedSemanticEntry] = []
    var sendability: [NormalizedSemanticEntry] = []

    mutating func sort() {
        declaration.sort(by: semanticEntryOrder)
        generics.sort(by: semanticEntryOrder)
        availability.sort(by: semanticEntryOrder)
        isolation.sort(by: semanticEntryOrder)
        sendability.sort(by: semanticEntryOrder)
    }
}

indirect enum NormalizedJSONValue: Hashable {
    case array([Self])
    case bool(Bool)
    case double(Double)
    case integer(Int64)
    case null
    case object([NormalizedJSONEntry])
    case string(String)
    case unsignedInteger(UInt64)

    var sortKey: String {
        switch self {
        case let .array(value): "a[\(value.map(\.sortKey).joined(separator: ","))]"
        case let .bool(value): "b\(value)"
        case let .double(value): "d\(value.bitPattern)"
        case let .integer(value): "i\(value)"
        case .null: "n"
        case let .object(value): "o{\(value.map(\.sortKey).joined(separator: ","))}"
        case let .string(value): "s\(value.count):\(value)"
        case let .unsignedInteger(value): "u\(value)"
        }
    }
}

struct NormalizedJSONEntry: Hashable {
    let key: String
    let value: NormalizedJSONValue

    var sortKey: String { "\(key.count):\(key)=\(value.sortKey)" }
}

extension CanonicalJSONValue {
    var containsSendable: Bool {
        switch self {
        case let .array(values): values.contains(where: \.containsSendable)
        case let .object(value):
            value.contains { $0.key.lowercased() == "sendable" || $0.value.containsSendable }
        case let .string(value): Self.sendabilityIdentifiers.contains(value)
        default: false
        }
    }

    private static var sendabilityIdentifiers: Set<String> {
        [
            "Sendable",
            "SendableMetatype",
            "Swift.Sendable",
            "Swift.SendableMetatype",
            "s:s8SendableP",
            "s:s16SendableMetatypeP",
        ]
    }

    var allStrings: [String] {
        switch self {
        case let .array(values): values.flatMap(\.allStrings)
        case let .object(value): value.values.flatMap(\.allStrings)
        case let .string(value): [value]
        default: []
        }
    }
}

extension AvailabilityPolicy {
    var permitsSurfaceDifference: Bool {
        self == .swift60CompilerFloor || self == .terminalCrossPlatform
    }
}

func relationshipOrder(_ lhs: NormalizedRelationship, _ rhs: NormalizedRelationship) -> Bool {
    let lhsKey = [lhs.kind, lhs.source, lhs.target, lhs.targetFallback ?? ""]
    let rhsKey = [rhs.kind, rhs.source, rhs.target, rhs.targetFallback ?? ""]
    if lhsKey != rhsKey {
        return lhsKey.lexicographicallyPrecedes(rhsKey)
    }
    return lhs.semanticDetails.map(\.sortKey)
        .lexicographicallyPrecedes(rhs.semanticDetails.map(\.sortKey))
}

func semanticEntryOrder(_ lhs: NormalizedSemanticEntry, _ rhs: NormalizedSemanticEntry) -> Bool {
    lhs.key == rhs.key ? lhs.value.sortKey < rhs.value.sortKey : lhs.key < rhs.key
}

func jsonEntryOrder(_ lhs: NormalizedJSONEntry, _ rhs: NormalizedJSONEntry) -> Bool {
    lhs.sortKey < rhs.sortKey
}

private extension NormalizedSemanticEntry {
    var sortKey: String { "\(key.count):\(key)=\(value.sortKey)" }
}
