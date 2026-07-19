@testable import APICompatibilityKit

struct SurfaceFixture {
    var manifest: CompatibilityManifest
    var referenceSet: APISnapshotSet
    var tuikitSet: APISnapshotSet
}

struct SurfaceSourceFixture {
    let id: String
    let moduleName: String
    let platform: String
    let symbols: [CanonicalSymbol]
    let relationships: [CanonicalRelationship]
}

enum ReferenceID {
    static let widget = "s:SwiftUI.Widget"
}

enum TUIkitID {
    static let widget = "s:TUIkit.Widget"
}

func exactFixture(
    tuikitModule: String = "TUIkit",
    includeShorterTUIkitModule: Bool = false,
    referenceSymbol: CanonicalSymbol? = nil,
    tuikitSymbol: CanonicalSymbol? = nil,
    referenceRelationships: [CanonicalRelationship] = [],
    tuikitRelationships: [CanonicalRelationship] = [],
    additionalReferenceSources: [SurfaceSourceFixture] = [],
    additionalTUIkitSources: [SurfaceSourceFixture] = []
) throws -> SurfaceFixture {
    let tuikitID = "s:\(tuikitModule).Widget"
    let reference = referenceSymbol ?? symbol(id: ReferenceID.widget, moduleName: "SwiftUI")
    let current = tuikitSymbol ?? symbol(id: tuikitID, moduleName: tuikitModule)
    var referenceSources = [
        sourceFixture(
            id: "reference-macos",
            moduleName: "SwiftUI",
            symbols: [reference],
            relationships: referenceRelationships
        ),
    ]
    referenceSources.append(contentsOf: additionalReferenceSources)
    var tuikitSources: [SurfaceSourceFixture] = []
    if includeShorterTUIkitModule {
        tuikitSources.append(
            sourceFixture(id: "tuikit-empty", moduleName: "TUIkit", symbols: [])
        )
    }
    tuikitSources.append(
        sourceFixture(
            id: "tuikit-macos",
            moduleName: tuikitModule,
            symbols: [current],
            relationships: tuikitRelationships
        )
    )
    tuikitSources.append(contentsOf: additionalTUIkitSources)

    let referenceEvidence = referenceSources.filter { source in
        source.symbols.contains { $0.preciseIdentifier == ReferenceID.widget }
    }.map {
        CompatibilityEvidence(kind: .referenceSymbolGraph, reference: $0.id)
    }
    let tuikitEvidence = tuikitSources.filter { source in
        source.symbols.contains { $0.preciseIdentifier == tuikitID }
    }.map {
        CompatibilityEvidence(kind: .tuikitSymbolGraph, reference: $0.id)
    }

    let manifest = CompatibilityManifest(
        schemaVersion: 2,
        referenceIDs: [ReferenceID.widget],
        decisions: [
            ReferenceDecision(
                referenceID: ReferenceID.widget,
                referenceSignature: reference.canonicalDeclaration,
                tuikitSignature: current.canonicalDeclaration,
                inclusion: .include,
                status: .verified,
                availability: AvailabilityDecision(policy: .matchesReference),
                evidence: referenceEvidence + tuikitEvidence + [
                    CompatibilityEvidence(kind: .compileContract, reference: "compile.widget"),
                ],
                ownerIssue: "#7",
                contractID: "compile.widget",
                tuikitSymbolID: tuikitID
            ),
        ],
        tuikitDecisions: [
            TUIkitSymbolDecision(
                symbolID: tuikitID,
                classification: .swiftUIExact,
                referenceID: ReferenceID.widget
            ),
        ]
    )
    return try SurfaceFixture(
        manifest: manifest,
        referenceSet: makeSet(name: "SwiftUI", sources: referenceSources),
        tuikitSet: makeSet(name: "TUIkit", sources: tuikitSources)
    )
}

func setException(
    in manifest: inout CompatibilityManifest,
    allowedDifferences: [CompatibilityDifference]
) {
    manifest.tuikitDecisions[0].classification = .reviewedException
    manifest.tuikitDecisions[0].exception = CompatibilityException(
        kind: .terminal,
        reason: "The terminal surface requires this reviewed difference.",
        allowedDifferences: allowedDifferences
    )
}

func sourceFixture(
    id: String,
    moduleName: String = "SwiftUI",
    platform: String = "macOS",
    symbols: [CanonicalSymbol],
    relationships: [CanonicalRelationship] = []
) -> SurfaceSourceFixture {
    SurfaceSourceFixture(
        id: id,
        moduleName: moduleName,
        platform: platform,
        symbols: symbols,
        relationships: relationships
    )
}

func makeSet(
    name: String,
    sources: [SurfaceSourceFixture]
) throws -> APISnapshotSet {
    let sortedSources = sources.sorted { $0.id < $1.id }
    let descriptors = sortedSources.map {
        APISnapshotSetSourceDescriptor(
            id: $0.id,
            moduleName: $0.moduleName,
            platform: $0.platform,
            targetTriple: "arm64-test-\($0.platform.lowercased())",
            sdkName: $0.platform.lowercased(),
            sdkVersion: "1.0",
            sdkBuild: "1A1",
            compilerVersion: "Swift 6.0",
            snapshotPath: "snapshots/\($0.id).json"
        )
    }
    let descriptor = APISnapshotSetDescriptor(
        schemaVersion: 2,
        name: name,
        requiredCoverage: Set(descriptors.map {
            APISnapshotCoverageRequirement(
                moduleName: $0.moduleName,
                platform: $0.platform
            )
        }).sorted {
            $0.moduleName == $1.moduleName
                ? $0.platform < $1.platform
                : $0.moduleName < $1.moduleName
        },
        sources: descriptors
    )
    let loaded = zip(descriptors, sortedSources).map { descriptor, fixture in
        LoadedAPISnapshotSetSource(
            source: descriptor,
            snapshot: APISnapshot(
                schemaVersion: 3,
                moduleName: fixture.moduleName,
                provenance: APISnapshotProvenance(
                    platform: descriptor.platform,
                    targetTriple: descriptor.targetTriple,
                    sdkName: descriptor.sdkName,
                    sdkVersion: descriptor.sdkVersion,
                    sdkBuild: descriptor.sdkBuild,
                    compilerVersion: descriptor.compilerVersion
                ),
                symbols: fixture.symbols,
                relationships: fixture.relationships
            )
        )
    }
    return try APISnapshotSet(descriptor: descriptor, sources: loaded)
}

func symbol(
    id: String,
    moduleName: String,
    declaration: String? = nil,
    semanticDetails: [String: CanonicalJSONValue]? = nil
) -> CanonicalSymbol {
    let renderedDeclaration = declaration
        ?? "func widget(_ value: \(moduleName).Value) -> \(moduleName).Text"
    return CanonicalSymbol(
        preciseIdentifier: id,
        kindIdentifier: "swift.func",
        title: "widget(_:)",
        pathComponents: ["Widget", "widget(_:)"],
        canonicalDeclaration: renderedDeclaration,
        declarationFragments: declarationFragments(
            symbolID: id,
            moduleName: moduleName,
            declaration: renderedDeclaration
        ),
        accessLevel: "public",
        semanticDetails: semanticDetails ?? baseSemanticDetails(moduleName: moduleName)
    )
}

func declarationFragments(
    symbolID: String,
    moduleName: String,
    declaration: String
) -> [CanonicalDeclarationFragment] {
    let standard = "func widget(_ value: \(moduleName).Value) -> \(moduleName).Text"
    guard declaration == standard else {
        return [
            CanonicalDeclarationFragment(kind: "text", spelling: declaration, preciseIdentifier: nil),
        ]
    }
    return [
        CanonicalDeclarationFragment(kind: "keyword", spelling: "func", preciseIdentifier: nil),
        CanonicalDeclarationFragment(kind: "text", spelling: " ", preciseIdentifier: nil),
        CanonicalDeclarationFragment(kind: "identifier", spelling: "widget", preciseIdentifier: symbolID),
        CanonicalDeclarationFragment(
            kind: "text",
            spelling: "(_ value: ",
            preciseIdentifier: nil
        ),
        CanonicalDeclarationFragment(
            kind: "typeIdentifier",
            spelling: "\(moduleName).Value",
            preciseIdentifier: nil
        ),
        CanonicalDeclarationFragment(kind: "text", spelling: ") -> ", preciseIdentifier: nil),
        CanonicalDeclarationFragment(
            kind: "typeIdentifier",
            spelling: "\(moduleName).Text",
            preciseIdentifier: nil
        ),
    ]
}

func baseSemanticDetails(moduleName: String) -> [String: CanonicalJSONValue] {
    [
        "functionSignature": .object([
            "parameters": .array([
                .object([
                    "declarationFragments": .array([
                        .object([
                            "kind": .string("identifier"),
                            "spelling": .string("value"),
                        ]),
                        .object([
                            "kind": .string("text"),
                            "spelling": .string(": "),
                        ]),
                        .object([
                            "kind": .string("typeIdentifier"),
                            "spelling": .string("\(moduleName).Value"),
                        ]),
                    ]),
                    "name": .string("value"),
                ]),
            ]),
            "returns": .array([
                .object([
                    "kind": .string("typeIdentifier"),
                    "spelling": .string("\(moduleName).Text"),
                ]),
            ]),
        ]),
    ]
}
