import Foundation

public struct CompatibilityManifest: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var referenceIDs: [String]
    public var decisions: [ReferenceDecision]
    public var tuikitDecisions: [TUIkitSymbolDecision]

    public init(
        schemaVersion: Int,
        referenceIDs: [String],
        decisions: [ReferenceDecision],
        tuikitDecisions: [TUIkitSymbolDecision]
    ) {
        self.schemaVersion = schemaVersion
        self.referenceIDs = referenceIDs
        self.decisions = decisions
        self.tuikitDecisions = tuikitDecisions
    }
}

public struct ReferenceDecision: Codable, Equatable, Sendable {
    public var referenceID: String
    public var referenceSignature: String
    public var tuikitSignature: String?
    public var inclusion: InclusionDecision
    public var status: DecisionStatus
    public var availability: AvailabilityDecision
    public var evidence: [CompatibilityEvidence]
    public var ownerIssue: String?
    public var contractID: String?
    public var tuikitSymbolID: String?
    public var exclusion: ExclusionDecision?

    public init(
        referenceID: String,
        referenceSignature: String,
        tuikitSignature: String? = nil,
        inclusion: InclusionDecision,
        status: DecisionStatus,
        availability: AvailabilityDecision,
        evidence: [CompatibilityEvidence],
        ownerIssue: String? = nil,
        contractID: String? = nil,
        tuikitSymbolID: String? = nil,
        exclusion: ExclusionDecision? = nil
    ) {
        self.referenceID = referenceID
        self.referenceSignature = referenceSignature
        self.tuikitSignature = tuikitSignature
        self.inclusion = inclusion
        self.status = status
        self.availability = availability
        self.evidence = evidence
        self.ownerIssue = ownerIssue
        self.contractID = contractID
        self.tuikitSymbolID = tuikitSymbolID
        self.exclusion = exclusion
    }
}

public enum InclusionDecision: String, Codable, CaseIterable, Sendable {
    case exclude
    case include
}

public enum DecisionStatus: String, Codable, CaseIterable, Sendable {
    case implemented
    case planned
    case unreviewed
    case verified
}

public struct AvailabilityDecision: Codable, Equatable, Sendable {
    public var policy: AvailabilityPolicy
    public var reason: String?

    public init(policy: AvailabilityPolicy, reason: String? = nil) {
        self.policy = policy
        self.reason = reason
    }
}

public enum AvailabilityPolicy: String, Codable, CaseIterable, Sendable {
    case excluded
    case matchesReference
    case swift60CompilerFloor
    case terminalCrossPlatform
}

public struct CompatibilityEvidence: Codable, Equatable, Hashable, Sendable {
    public var kind: CompatibilityEvidenceKind
    public var reference: String

    public init(kind: CompatibilityEvidenceKind, reference: String) {
        self.kind = kind
        self.reference = reference
    }
}

public enum CompatibilityEvidenceKind: String, Codable, CaseIterable, Sendable {
    case behaviorContract
    case compileContract
    case documentation
    case referenceSymbolGraph
    case tuikitSymbolGraph
}

public struct ExclusionDecision: Codable, Equatable, Sendable {
    public var category: ExclusionCategory
    public var reason: String

    public init(category: ExclusionCategory, reason: String) {
        self.category = category
        self.reason = reason
    }
}

public enum ExclusionCategory: String, Codable, CaseIterable, Sendable {
    case appleRepresentable
    case rasterOrGPU
    case touchOrSpatialInput
    case windowServer
}

public struct TUIkitSymbolDecision: Codable, Equatable, Sendable {
    public var symbolID: String
    public var classification: TUIkitClassification
    public var referenceID: String?
    public var ownerIssue: String?
    public var exception: CompatibilityException?

    public init(
        symbolID: String,
        classification: TUIkitClassification,
        referenceID: String? = nil,
        ownerIssue: String? = nil,
        exception: CompatibilityException? = nil
    ) {
        self.symbolID = symbolID
        self.classification = classification
        self.referenceID = referenceID
        self.ownerIssue = ownerIssue
        self.exception = exception
    }
}

public enum TUIkitClassification: String, Codable, CaseIterable, Sendable {
    case implementationLeak
    case reviewedException
    case swiftUIExact
    case tuiSpecific
}

public struct CompatibilityException: Codable, Equatable, Sendable {
    public var kind: CompatibilityExceptionKind
    public var reason: String
    public var allowedDifferences: [CompatibilityDifference]

    public init(
        kind: CompatibilityExceptionKind,
        reason: String,
        allowedDifferences: [CompatibilityDifference]
    ) {
        self.kind = kind
        self.reason = reason
        self.allowedDifferences = allowedDifferences
    }
}

public enum CompatibilityExceptionKind: String, Codable, CaseIterable, Sendable {
    case compilerFloor
    case terminal
}

public enum CompatibilityDifference: String, Codable, CaseIterable, Hashable, Sendable {
    case availability
    case declaration
    case generics
    case isolation
    case kind
    case relationships
    case sendability
}

public struct ManifestLoader: Sendable {
    public init() {}

    public func load(from url: URL) throws -> CompatibilityManifest {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CompatibilityManifest.self, from: data)
        } catch {
            throw APICheckDiagnostic(
                code: "manifest.invalid-json",
                message: "\(url.lastPathComponent) is not a valid compatibility manifest"
            )
        }
    }
}
