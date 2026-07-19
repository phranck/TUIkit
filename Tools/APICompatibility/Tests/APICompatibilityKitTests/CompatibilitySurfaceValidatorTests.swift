import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Compatibility surface validator")
struct CompatibilitySurfaceValidatorTests {
    @Test("Accepts an exact surface after recursive module and precise ID normalization")
    func acceptsExactNormalizedSurface() throws {
        let fixture = try exactFixture(
            tuikitModule: "TUIkitCore",
            includeShorterTUIkitModule: true
        )

        let diagnostics = validate(fixture)

        #expect(diagnostics.isEmpty)
    }

    @Test("Requires exact reference and TUIkit union inventories")
    func validatesUnionInventories() throws {
        var fixture = try exactFixture()
        fixture.manifest.referenceIDs = []
        fixture.manifest.tuikitDecisions = []

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("surface.reference-inventory-unexpected"))
        #expect(diagnostics.map(\.code).contains("surface.tuikit-inventory-unexpected"))
    }

    @Test("Every canonical platform declaration must prove the recorded signatures")
    func validatesEveryRecordedSignature() throws {
        let wrongReference = symbol(
            id: ReferenceID.widget,
            moduleName: "SwiftUI",
            declaration: "func widget(_ value: SwiftUI.Other) -> SwiftUI.Text"
        )
        let wrongTUIkit = symbol(
            id: TUIkitID.widget,
            moduleName: "TUIkit",
            declaration: "func widget(_ value: TUIkit.Other) -> TUIkit.Text"
        )
        let fixture = try exactFixture(
            additionalReferenceSources: [
                sourceFixture(id: "reference-ios", platform: "iOS", symbols: [wrongReference]),
                sourceFixture(id: "reference-watch", platform: "watchOS", symbols: [wrongReference]),
            ],
            additionalTUIkitSources: [
                sourceFixture(
                    id: "tuikit-linux",
                    moduleName: "TUIkit",
                    platform: "Linux",
                    symbols: [wrongTUIkit]
                ),
            ]
        )

        let diagnostics = validate(fixture)

        #expect(diagnostics.filter { $0.code == "surface.reference-signature" }.count == 1)
        #expect(diagnostics.filter { $0.code == "surface.tuikit-signature" }.count == 1)
        #expect(
            diagnostics.first { $0.code == "surface.reference-signature" }?.message
                .contains("reference-ios") == true
        )
    }

    @Test("Matching IDs cannot hide an incompatible declaration")
    func rejectsDeclarationMismatch() throws {
        let changedDeclaration = "func widget(_ value: TUIkit.Value, count: Int) -> TUIkit.Text"
        var fixture = try exactFixture(
            tuikitSymbol: symbol(
                id: TUIkitID.widget,
                moduleName: "TUIkit",
                declaration: changedDeclaration
            )
        )
        fixture.manifest.decisions[0].tuikitSignature = changedDeclaration

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("surface.declaration"))
    }

    @Test("Does not normalize module names inside string literals")
    func preservesStringLiteralText() throws {
        let currentDeclaration = "func widget(_ value: String = \"TUIkit\")"
        var fixture = try exactFixture(
            referenceSymbol: symbol(
                id: ReferenceID.widget,
                moduleName: "SwiftUI",
                declaration: "func widget(_ value: String = \"SwiftUI\")"
            ),
            tuikitSymbol: symbol(
                id: TUIkitID.widget,
                moduleName: "TUIkit",
                declaration: currentDeclaration
            )
        )
        fixture.manifest.decisions[0].tuikitSignature = currentDeclaration

        #expect(validate(fixture).map(\.code).contains("surface.declaration"))
    }

    @Test("Does not normalize module names embedded in identifiers")
    func preservesIdentifierText() throws {
        let currentDeclaration = "func makeTUIkitWidget()"
        var fixture = try exactFixture(
            referenceSymbol: symbol(
                id: ReferenceID.widget,
                moduleName: "SwiftUI",
                declaration: "func makeSwiftUIWidget()"
            ),
            tuikitSymbol: symbol(
                id: TUIkitID.widget,
                moduleName: "TUIkit",
                declaration: currentDeclaration
            )
        )
        fixture.manifest.decisions[0].tuikitSignature = currentDeclaration

        #expect(validate(fixture).map(\.code).contains("surface.declaration"))
    }

    @Test("Declaration fragment target IDs use only the bidirectional manifest map")
    func rejectsDeclarationTargetMismatch() throws {
        var changed = symbol(id: TUIkitID.widget, moduleName: "TUIkit")
        changed.declarationFragments[2].preciseIdentifier = "s:External.Widget"
        let fixture = try exactFixture(tuikitSymbol: changed)

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("surface.declaration"))
    }

    @Test("Reports semantic differences by compatibility dimension")
    func reportsSemanticDimensions() throws {
        let cases: [(key: String, reference: CanonicalJSONValue, current: CanonicalJSONValue, code: String)] = [
            ("swiftGenerics", .string("T == SwiftUI.Value"), .string("T == TUIkit.Other"), "surface.generics"),
            ("availability", .string("macOS 15"), .string("macOS 14"), "surface.availability"),
            ("swiftActorIsolation", .string("MainActor"), .string("nonisolated"), "surface.isolation"),
            ("customMixin", .string("SwiftUI.Value"), .string("TUIkit.Other"), "surface.declaration"),
        ]

        for testCase in cases {
            var reference = baseSemanticDetails(moduleName: "SwiftUI")
            var current = baseSemanticDetails(moduleName: "TUIkit")
            reference[testCase.key] = testCase.reference
            current[testCase.key] = testCase.current
            let fixture = try exactFixture(
                referenceSymbol: symbol(
                    id: ReferenceID.widget,
                    moduleName: "SwiftUI",
                    semanticDetails: reference
                ),
                tuikitSymbol: symbol(
                    id: TUIkitID.widget,
                    moduleName: "TUIkit",
                    semanticDetails: current
                )
            )

            #expect(validate(fixture).map(\.code).contains(testCase.code))
        }
    }
}

extension CompatibilitySurfaceValidatorTests {
    @Test("Treats Sendable conformances as sendability")
    func reportsSendability() throws {
        let sendable = CanonicalRelationship(
            kind: "conformsTo",
            source: ReferenceID.widget,
            target: "s:s8SendableP",
            targetFallback: "Swift.Sendable"
        )
        let fixture = try exactFixture(referenceRelationships: [sendable])

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("surface.sendability"))
        #expect(diagnostics.map(\.code).contains("surface.relationships") == false)
    }

    @Test("Protocol names containing Sendable remain ordinary relationships")
    func doesNotMisclassifySendabilityBySubstring() throws {
        let ordinaryConformance = CanonicalRelationship(
            kind: "conformsTo",
            source: ReferenceID.widget,
            target: "s:Example.NonSendableProtocol",
            targetFallback: "Example.NonSendableProtocol"
        )
        let fixture = try exactFixture(referenceRelationships: [ordinaryConformance])

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("surface.relationships"))
        #expect(diagnostics.map(\.code).contains("surface.sendability") == false)
    }

    @Test("Compares source relationships including external target fallbacks")
    func reportsRelationshipFallbackMismatch() throws {
        let referenceRelationship = CanonicalRelationship(
            kind: "conformsTo",
            source: ReferenceID.widget,
            target: "s:External.Protocol",
            targetFallback: "External.Protocol"
        )
        let tuikitRelationship = CanonicalRelationship(
            kind: "conformsTo",
            source: TUIkitID.widget,
            target: "s:External.Protocol",
            targetFallback: "External.OtherProtocol"
        )
        let fixture = try exactFixture(
            referenceRelationships: [referenceRelationship],
            tuikitRelationships: [tuikitRelationship]
        )

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("surface.relationships"))
    }

    @Test("A differing platform variant cannot hide behind a compatible first occurrence")
    func validatesAllPlatformOccurrences() throws {
        var variantDetails = baseSemanticDetails(moduleName: "TUIkit")
        variantDetails["swiftGenerics"] = .string("T == TUIkit.Other")
        let variant = symbol(
            id: TUIkitID.widget,
            moduleName: "TUIkit",
            semanticDetails: variantDetails
        )
        let fixture = try exactFixture(
            additionalTUIkitSources: [
                sourceFixture(
                    id: "tuikit-linux",
                    moduleName: "TUIkit",
                    platform: "Linux",
                    symbols: [variant]
                ),
            ]
        )

        let diagnostics = validate(fixture)

        let genericDiagnostic = diagnostics.first { $0.code == "surface.generics" }
        #expect(genericDiagnostic != nil)
        #expect(genericDiagnostic?.message.contains("tuikit-linux") == true)
    }

    @Test("Source identity prevents swapped platform variants from matching")
    func rejectsSwappedPlatformVariants() throws {
        var referenceMacDetails = baseSemanticDetails(moduleName: "SwiftUI")
        referenceMacDetails["swiftGenerics"] = .string("A")
        var referenceIOSDetails = baseSemanticDetails(moduleName: "SwiftUI")
        referenceIOSDetails["swiftGenerics"] = .string("B")
        var tuikitMacDetails = baseSemanticDetails(moduleName: "TUIkit")
        tuikitMacDetails["swiftGenerics"] = .string("B")
        var tuikitLinuxDetails = baseSemanticDetails(moduleName: "TUIkit")
        tuikitLinuxDetails["swiftGenerics"] = .string("A")
        let fixture = try exactFixture(
            referenceSymbol: symbol(
                id: ReferenceID.widget,
                moduleName: "SwiftUI",
                semanticDetails: referenceMacDetails
            ),
            tuikitSymbol: symbol(
                id: TUIkitID.widget,
                moduleName: "TUIkit",
                semanticDetails: tuikitMacDetails
            ),
            additionalReferenceSources: [
                sourceFixture(
                    id: "reference-ios",
                    platform: "iOS",
                    symbols: [
                        symbol(
                            id: ReferenceID.widget,
                            moduleName: "SwiftUI",
                            semanticDetails: referenceIOSDetails
                        ),
                    ]
                ),
            ],
            additionalTUIkitSources: [
                sourceFixture(
                    id: "tuikit-linux",
                    moduleName: "TUIkit",
                    platform: "Linux",
                    symbols: [
                        symbol(
                            id: TUIkitID.widget,
                            moduleName: "TUIkit",
                            semanticDetails: tuikitLinuxDetails
                        ),
                    ]
                ),
            ]
        )

        let diagnostic = validate(fixture).first { $0.code == "surface.generics" }

        #expect(diagnostic != nil)
        #expect(diagnostic?.message.contains("reference-macos (SwiftUI/macOS)") == true)
        #expect(diagnostic?.message.contains("tuikit-macos (TUIkit/macOS)") == true)
    }

    @Test("External relationship sources remain part of the mapped surface")
    func validatesExternalSourceRelationships() throws {
        let externalConformance = CanonicalRelationship(
            kind: "conformsTo",
            source: "s:External.Widget",
            target: ReferenceID.widget,
            targetFallback: nil
        )
        let fixture = try exactFixture(referenceRelationships: [externalConformance])

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("surface.relationships"))
    }

    @Test("Relationships without a local symbol anchor fail closed")
    func rejectsUnownedRelationships() throws {
        let unowned = CanonicalRelationship(
            kind: "conformsTo",
            source: "s:External.Widget",
            target: "s:External.Protocol",
            targetFallback: "External.Protocol"
        )
        let fixture = try exactFixture(referenceRelationships: [unowned])

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("surface.reference-relationship-unowned"))
    }

    @Test("Compiler-intrinsic Never conformances are not attributed to SwiftUI")
    func acceptsCompilerIntrinsicForeignConformances() throws {
        let intrinsic = CanonicalRelationship(
            kind: "conformsTo",
            source: "s:s5NeverO",
            target: "s:s8CopyableP",
            targetFallback: "Swift.Copyable"
        )
        let fixture = try exactFixture(referenceRelationships: [intrinsic])

        #expect(validate(fixture).isEmpty)
    }

    @Test("Foreign standard conformances from extension graphs are not attributed to SwiftUI")
    func acceptsForeignStandardConformances() throws {
        let conformances = [
            CanonicalRelationship(
                kind: "conformsTo",
                source: "c:@S@CGPoint",
                target: "s:s8CopyableP",
                targetFallback: "Swift.Copyable"
            ),
            CanonicalRelationship(
                kind: "conformsTo",
                source: "c:@S@CGRect",
                target: "s:s9EscapableP",
                targetFallback: "Swift.Escapable"
            ),
            CanonicalRelationship(
                kind: "conformsTo",
                source: "s:Sd",
                target: "s:SQ",
                targetFallback: "Swift.Equatable"
            ),
            CanonicalRelationship(
                kind: "conformsTo",
                source: "s:Sf",
                target: "s:s18AdditiveArithmeticP",
                targetFallback: "Swift.AdditiveArithmetic"
            ),
            CanonicalRelationship(
                kind: "conformsTo",
                source: "s:s5NeverO",
                target: "s:s8SendableP",
                targetFallback: "Swift.Sendable"
            ),
            CanonicalRelationship(
                kind: "conformsTo",
                source: "s:s5NeverO",
                target: "s:s16SendableMetatypeP",
                targetFallback: "Swift.SendableMetatype"
            ),
        ]
        let fixture = try exactFixture(referenceRelationships: conformances)

        #expect(validate(fixture).isEmpty)
    }

    @Test("Reviewed exceptions require an exact and fully used allowlist")
    func validatesExceptionAllowlist() throws {
        var referenceDetails = baseSemanticDetails(moduleName: "SwiftUI")
        var currentDetails = baseSemanticDetails(moduleName: "TUIkit")
        referenceDetails["swiftGenerics"] = .string("T == SwiftUI.Value")
        currentDetails["swiftGenerics"] = .string("T == TUIkit.Other")
        let base = try exactFixture(
            referenceSymbol: symbol(
                id: ReferenceID.widget,
                moduleName: "SwiftUI",
                semanticDetails: referenceDetails
            ),
            tuikitSymbol: symbol(
                id: TUIkitID.widget,
                moduleName: "TUIkit",
                semanticDetails: currentDetails
            )
        )

        var allowed = base
        setException(in: &allowed.manifest, allowedDifferences: [.generics])
        #expect(validate(allowed).isEmpty)

        var unused = base
        setException(in: &unused.manifest, allowedDifferences: [.generics, .isolation])
        #expect(validate(unused).map(\.code).contains("surface.exception-unused-difference"))

        var disallowed = base
        setException(in: &disallowed.manifest, allowedDifferences: [.isolation])
        let disallowedCodes = validate(disallowed).map(\.code)
        #expect(disallowedCodes.contains("surface.generics"))
        #expect(disallowedCodes.contains("surface.exception-unused-difference"))
    }

    @Test("Availability exceptions also require a permissive availability policy")
    func validatesAvailabilityPolicy() throws {
        var referenceDetails = baseSemanticDetails(moduleName: "SwiftUI")
        var currentDetails = baseSemanticDetails(moduleName: "TUIkit")
        referenceDetails["availability"] = .string("macOS 15")
        currentDetails["availability"] = .string("Linux")
        let base = try exactFixture(
            referenceSymbol: symbol(
                id: ReferenceID.widget,
                moduleName: "SwiftUI",
                semanticDetails: referenceDetails
            ),
            tuikitSymbol: symbol(
                id: TUIkitID.widget,
                moduleName: "TUIkit",
                semanticDetails: currentDetails
            )
        )

        var rejected = base
        setException(in: &rejected.manifest, allowedDifferences: [.availability])
        #expect(validate(rejected).map(\.code).contains("surface.availability-policy"))

        var accepted = base
        setException(in: &accepted.manifest, allowedDifferences: [.availability])
        accepted.manifest.decisions[0].availability = AvailabilityDecision(
            policy: .terminalCrossPlatform,
            reason: "TUIkit supports terminals on every platform."
        )
        #expect(validate(accepted).isEmpty)

        var exact = base
        exact.manifest.decisions[0].availability = AvailabilityDecision(
            policy: .terminalCrossPlatform,
            reason: "TUIkit supports terminals on every platform."
        )
        #expect(validate(exact).map(\.code).contains("surface.availability"))
    }

    @Test("TUI-specific symbols cannot collide with a SwiftUI overload")
    func rejectsTUISpecificCollision() throws {
        var fixture = try exactFixture()
        let collisionID = "s:TUIkit.TerminalWidget"
        let collision = symbol(
            id: collisionID,
            moduleName: "TUIkit",
            declaration: "func widget(_ value: TUIkit.Other) -> TUIkit.Text"
        )
        fixture.manifest.tuikitDecisions.append(
            TUIkitSymbolDecision(symbolID: collisionID, classification: .tuiSpecific)
        )
        fixture.tuikitSet = try makeSet(
            name: "TUIkit",
            sources: [
                sourceFixture(
                    id: "tuikit-macos",
                    moduleName: "TUIkit",
                    symbols: [symbol(id: TUIkitID.widget, moduleName: "TUIkit"), collision]
                ),
            ]
        )

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("surface.tui-specific-collision"))
        #expect(diagnostics == diagnostics.sorted())
    }

    private func validate(_ fixture: SurfaceFixture) -> [APICheckDiagnostic] {
        CompatibilitySurfaceValidator().validate(
            fixture.manifest,
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )
    }
}
