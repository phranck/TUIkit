import Testing

@testable import APICompatibilityKit

@Suite("Compatibility contract link validator")
struct CompatibilityContractLinkValidatorTests {
    @Test("Accepts compile and behavior contracts with matching evidence")
    func acceptsMatchingContractLinks() {
        let manifest = linkManifest([
            linkDecision(
                referenceID: "s:SwiftUI.Compile",
                contractID: "compile.text",
                evidence: [linkEvidence(.compileContract, "compile.text")]
            ),
            linkDecision(
                referenceID: "s:SwiftUI.Behavior",
                contractID: "behavior.focus",
                evidence: [linkEvidence(.behaviorContract, "behavior.focus")]
            ),
        ])
        let registry = linkRegistry([
            linkCompileDefinition("compile.text"),
            linkBehaviorDefinition("behavior.focus"),
        ])

        let diagnostics = CompatibilityContractLinkValidator().validate(
            manifest,
            registry: registry
        )

        #expect(diagnostics.isEmpty)
    }

    @Test("Requires exactly one matching contract evidence")
    func requiresExactlyOneMatchingEvidence() {
        let duplicateEvidence = linkEvidence(.compileContract, "compile.duplicate")
        let manifest = linkManifest([
            linkDecision(referenceID: "s:SwiftUI.Missing", contractID: "compile.missing"),
            linkDecision(
                referenceID: "s:SwiftUI.Duplicate",
                contractID: "compile.duplicate",
                evidence: [duplicateEvidence, duplicateEvidence]
            ),
        ])
        let registry = linkRegistry([
            linkCompileDefinition("compile.missing"),
            linkCompileDefinition("compile.duplicate"),
        ])

        let diagnostics = CompatibilityContractLinkValidator().validate(
            manifest,
            registry: registry
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-link.evidence-count",
                message: "Included reference 's:SwiftUI.Duplicate' requires exactly one contract evidence "
                    + "for 'compile.duplicate'; found 2"
            ),
            APICheckDiagnostic(
                code: "contract-link.evidence-count",
                message: "Included reference 's:SwiftUI.Missing' requires exactly one contract evidence "
                    + "for 'compile.missing'; found 0"
            ),
        ])
    }

    @Test("Matches evidence kind to the registered contract kind")
    func requiresEvidenceKindMatchingRegistry() {
        let manifest = linkManifest([
            linkDecision(
                referenceID: "s:SwiftUI.Compile",
                contractID: "compile.text",
                evidence: [linkEvidence(.behaviorContract, "compile.text")]
            ),
            linkDecision(
                referenceID: "s:SwiftUI.Behavior",
                contractID: "behavior.focus",
                evidence: [linkEvidence(.compileContract, "behavior.focus")]
            ),
        ])
        let registry = linkRegistry([
            linkCompileDefinition("compile.text"),
            linkBehaviorDefinition("behavior.focus"),
        ])

        let diagnostics = CompatibilityContractLinkValidator().validate(
            manifest,
            registry: registry
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-link.evidence-kind",
                message: "Included reference 's:SwiftUI.Behavior' links contract 'behavior.focus' "
                    + "with 'compileContract' evidence; expected 'behaviorContract'"
            ),
            APICheckDiagnostic(
                code: "contract-link.evidence-kind",
                message: "Included reference 's:SwiftUI.Compile' links contract 'compile.text' "
                    + "with 'behaviorContract' evidence; expected 'compileContract'"
            ),
        ])
    }

    @Test("Does not let excluded decisions satisfy registry coverage")
    func excludedDecisionDoesNotReferenceContract() {
        let contractID = "behavior.excluded"
        let manifest = linkManifest([
            linkDecision(
                referenceID: "s:SwiftUI.Excluded",
                inclusion: .exclude,
                contractID: contractID,
                evidence: [linkEvidence(.behaviorContract, contractID)]
            ),
        ])

        let diagnostics = CompatibilityContractLinkValidator().validate(
            manifest,
            registry: linkRegistry([linkBehaviorDefinition(contractID)])
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-link.noninclude-contract-id",
                message: "Excluded reference 's:SwiftUI.Excluded' cannot reference contract 'behavior.excluded'"
            ),
            APICheckDiagnostic(
                code: "contract-link.noninclude-evidence",
                message: "Excluded reference 's:SwiftUI.Excluded' cannot contain contract evidence"
            ),
            APICheckDiagnostic(
                code: "contract-registry.unused-contract",
                message: "Registered contract 'behavior.excluded' is not referenced"
            ),
        ])
    }

    @Test("Validates unreviewed includes instead of filtering them out")
    func unreviewedIncludeRemainsVisible() {
        let manifest = linkManifest([
            linkDecision(
                referenceID: "s:SwiftUI.Pending",
                status: .unreviewed,
                contractID: "compile.pending",
                evidence: [linkEvidence(.behaviorContract, "compile.pending")]
            ),
        ])

        let diagnostics = CompatibilityContractLinkValidator().validate(
            manifest,
            registry: linkRegistry([linkCompileDefinition("compile.pending")])
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-link.evidence-kind",
                message: "Included reference 's:SwiftUI.Pending' links contract 'compile.pending' "
                    + "with 'behaviorContract' evidence; expected 'compileContract'"
            ),
        ])
    }

    @Test("Validates every duplicate decision independently")
    func duplicateDecisionCannotHideInvalidEvidence() {
        let contractID = "compile.duplicate-reference"
        let manifest = linkManifest([
            linkDecision(
                referenceID: "s:SwiftUI.Duplicate",
                contractID: contractID,
                evidence: [linkEvidence(.compileContract, contractID)]
            ),
            linkDecision(
                referenceID: "s:SwiftUI.Duplicate",
                contractID: contractID
            ),
        ])

        let diagnostics = CompatibilityContractLinkValidator().validate(
            manifest,
            registry: linkRegistry([linkCompileDefinition(contractID)])
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-link.evidence-count",
                message: "Included reference 's:SwiftUI.Duplicate' requires exactly one contract evidence "
                    + "for 'compile.duplicate-reference'; found 0"
            ),
        ])
    }

    @Test("Rejects missing, empty, and unknown contract IDs")
    func rejectsInvalidContractIDs() {
        let manifest = linkManifest([
            linkDecision(referenceID: "s:SwiftUI.Nil", contractID: nil),
            linkDecision(referenceID: "s:SwiftUI.Empty", contractID: " \n"),
            linkDecision(
                referenceID: "s:SwiftUI.Unknown",
                contractID: "compile.unknown",
                evidence: [linkEvidence(.compileContract, "compile.unknown")]
            ),
        ])

        let diagnostics = CompatibilityContractLinkValidator().validate(
            manifest,
            registry: linkRegistry([linkCompileDefinition("compile.unused")])
        )

        #expect(diagnostics.map(\.code) == [
            "contract-link.missing-contract-id",
            "contract-link.missing-contract-id",
            "contract-link.unknown-evidence-id",
            "contract-registry.empty-reference",
            "contract-registry.unknown-reference",
            "contract-registry.unused-contract",
        ])
        #expect(diagnostics == diagnostics.sorted())
    }

    @Test("Rejects empty, unknown, and unrelated contract evidence IDs")
    func rejectsInvalidEvidenceIDs() {
        let manifest = linkManifest([
            linkDecision(
                referenceID: "s:SwiftUI.Evidence",
                contractID: "compile.primary",
                evidence: [
                    linkEvidence(.compileContract, "compile.primary"),
                    linkEvidence(.compileContract, ""),
                    linkEvidence(.behaviorContract, "behavior.unknown"),
                    linkEvidence(.compileContract, "compile.secondary"),
                ]
            ),
            linkDecision(
                referenceID: "s:SwiftUI.Secondary",
                contractID: "compile.secondary",
                evidence: [linkEvidence(.compileContract, "compile.secondary")]
            ),
        ])
        let registry = linkRegistry([
            linkCompileDefinition("compile.primary"),
            linkCompileDefinition("compile.secondary"),
        ])

        let diagnostics = CompatibilityContractLinkValidator().validate(
            manifest,
            registry: registry
        )

        #expect(diagnostics.map(\.code) == [
            "contract-link.empty-evidence-id",
            "contract-link.unknown-evidence-id",
            "contract-link.unmatched-evidence-id",
            "contract-link.unmatched-evidence-id",
        ])
        #expect(diagnostics == diagnostics.sorted())
    }

    @Test("Requires each referenced contract ID to be registered exactly once")
    func rejectsAmbiguousRegistryContract() {
        let contractID = "compile.ambiguous"
        let manifest = linkManifest([
            linkDecision(
                referenceID: "s:SwiftUI.Ambiguous",
                contractID: contractID,
                evidence: [linkEvidence(.compileContract, contractID)]
            ),
        ])
        let registry = linkRegistry([
            linkCompileDefinition(contractID),
            linkCompileDefinition(contractID),
        ])

        let diagnostics = CompatibilityContractLinkValidator().validate(
            manifest,
            registry: registry
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-link.ambiguous-contract",
                message: "Included reference 's:SwiftUI.Ambiguous' references contract 'compile.ambiguous', "
                    + "which is registered 2 times"
            ),
            APICheckDiagnostic(
                code: "contract-registry.duplicate-id",
                message: "Contract ID 'compile.ambiguous' is registered more than once"
            ),
        ])
    }
}

private func linkManifest(_ decisions: [ReferenceDecision]) -> CompatibilityManifest {
    CompatibilityManifest(
        schemaVersion: 2,
        referenceIDs: decisions.map(\.referenceID),
        decisions: decisions,
        tuikitDecisions: []
    )
}

private func linkDecision(
    referenceID: String,
    inclusion: InclusionDecision = .include,
    status: DecisionStatus = .planned,
    contractID: String?,
    evidence: [CompatibilityEvidence] = []
) -> ReferenceDecision {
    ReferenceDecision(
        referenceID: referenceID,
        referenceSignature: "public struct Fixture: View",
        inclusion: inclusion,
        status: status,
        availability: AvailabilityDecision(
            policy: inclusion == .include ? .terminalCrossPlatform : .excluded,
            reason: "Contract link fixture"
        ),
        evidence: evidence,
        contractID: contractID
    )
}

private func linkEvidence(
    _ kind: CompatibilityEvidenceKind,
    _ reference: String
) -> CompatibilityEvidence {
    CompatibilityEvidence(kind: kind, reference: reference)
}

private func linkRegistry(_ contracts: [ContractDefinition]) -> CompatibilityContractRegistry {
    CompatibilityContractRegistry(schemaVersion: 1, contracts: contracts)
}

private func linkCompileDefinition(_ id: String) -> ContractDefinition {
    ContractDefinition(
        id: id,
        kind: .compile,
        compile: CompileContract(
            fixture: "Positive.swift",
            expectation: CompileContractExpectation(outcome: .succeeds)
        )
    )
}

private func linkBehaviorDefinition(_ id: String) -> ContractDefinition {
    ContractDefinition(
        id: id,
        kind: .behavior,
        testIdentifier: "APICompatibilityKitTests.linkBehavior"
    )
}
