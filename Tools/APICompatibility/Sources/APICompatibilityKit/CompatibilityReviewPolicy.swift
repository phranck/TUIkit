import Foundation

public struct CompatibilityReviewPolicy: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var referenceRules: [ReferenceReviewRule]
    public var tuikitOverrides: [TUIkitReviewOverride]

    public init(
        schemaVersion: Int,
        referenceRules: [ReferenceReviewRule],
        tuikitOverrides: [TUIkitReviewOverride]
    ) {
        self.schemaVersion = schemaVersion
        self.referenceRules = referenceRules
        self.tuikitOverrides = tuikitOverrides
    }
}

public struct ReferenceReviewRule: Codable, Equatable, Sendable {
    public var id: String
    public var referenceIDs: [String]
    public var action: ReferenceReviewAction

    public init(id: String, referenceIDs: [String], action: ReferenceReviewAction) {
        self.id = id
        self.referenceIDs = referenceIDs
        self.action = action
    }
}

public struct ReferenceReviewAction: Codable, Equatable, Sendable {
    public var kind: InclusionDecision
    public var category: ExclusionCategory?
    public var reason: String?
    public var ownerIssue: String?
    public var status: DecisionStatus?
    public var contractID: String?
    public var contractKind: ReviewContractKind?
    public var plannedTUIkitSignatures: [String: String]?
    public var availability: AvailabilityDecision?

    public init(
        kind: InclusionDecision,
        category: ExclusionCategory? = nil,
        reason: String? = nil,
        ownerIssue: String? = nil,
        status: DecisionStatus? = nil,
        contractID: String? = nil,
        contractKind: ReviewContractKind? = nil,
        plannedTUIkitSignatures: [String: String]? = nil,
        availability: AvailabilityDecision? = nil
    ) {
        self.kind = kind
        self.category = category
        self.reason = reason
        self.ownerIssue = ownerIssue
        self.status = status
        self.contractID = contractID
        self.contractKind = contractKind
        self.plannedTUIkitSignatures = plannedTUIkitSignatures
        self.availability = availability
    }
}

public enum ReviewContractKind: String, Codable, CaseIterable, Sendable {
    case behavior
    case compile
}

public struct TUIkitReviewOverride: Codable, Equatable, Sendable {
    public var symbolID: String
    public var action: TUIkitReviewAction
    public var referenceID: String?
    public var ownerIssue: String?
    public var exception: CompatibilityException?

    public init(
        symbolID: String,
        action: TUIkitReviewAction,
        referenceID: String? = nil,
        ownerIssue: String? = nil,
        exception: CompatibilityException? = nil
    ) {
        self.symbolID = symbolID
        self.action = action
        self.referenceID = referenceID
        self.ownerIssue = ownerIssue
        self.exception = exception
    }
}

public enum TUIkitReviewAction: String, Codable, CaseIterable, Sendable {
    case implementationLeak
    case mapExact
    case mapReviewedException
    case tuiSpecific
}

public struct CompatibilityReviewPolicyCodec: Sendable {
    public init() {}

    public func load(from url: URL) throws -> CompatibilityReviewPolicy {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CompatibilityReviewPolicy.self, from: data)
        } catch {
            throw APICheckDiagnostic(
                code: "review-policy.invalid-json",
                message: "\(url.lastPathComponent) is not a valid compatibility review policy"
            )
        }
    }
}
