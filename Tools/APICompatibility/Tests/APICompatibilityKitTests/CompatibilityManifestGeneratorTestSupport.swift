import Foundation

@testable import APICompatibilityKit

struct GeneratorFixture {
    let referenceSet: APISnapshotSet
    let tuikitSet: APISnapshotSet
}

func manifestGenerator(
    ownerRegistry: CompatibilityOwnerRegistry? = nil
) throws -> CompatibilityManifestGenerator {
    CompatibilityManifestGenerator(
        ownerRegistry: try ownerRegistry ?? CompatibilityOwnerRegistryCodec().load(
            from: FixtureSupport.url("Policies/owners.json")
        )
    )
}

func generatorFixture(
    referenceWidgetTypeModule: String? = nil,
    tuikitWidgetDeclarationSuffix: String = "",
    referenceWidgetAvailability: String? = nil,
    tuikitWidgetAvailability: String? = nil,
    includeAmbiguousWidget: Bool = false
) throws -> GeneratorFixture {
    let referenceSet = try makeSet(
        name: "SwiftUI reference",
        sources: [
            sourceFixture(
                id: "reference-swiftui-macos",
                moduleName: "SwiftUI",
                symbols: [
                    generatorSymbol(
                        id: "s:SwiftUI.Widget",
                        moduleName: "SwiftUI",
                        name: "widget",
                        typeModuleName: referenceWidgetTypeModule,
                        availability: referenceWidgetAvailability
                    ),
                    generatorSymbol(
                        id: "s:SwiftUI.ImageRenderer",
                        moduleName: "SwiftUI",
                        name: "imageRenderer"
                    ),
                ]
            ),
            sourceFixture(
                id: "reference-swiftuicore-macos",
                moduleName: "SwiftUICore",
                symbols: [
                    generatorSymbol(
                        id: "s:SwiftUICore.Gadget",
                        moduleName: "SwiftUICore",
                        name: "gadget"
                    ),
                ]
            ),
        ]
    )
    var tuikitSymbols = [
        generatorSymbol(
            id: "s:TUIkit.Widget",
            moduleName: "TUIkit",
            name: "widget",
            declarationSuffix: tuikitWidgetDeclarationSuffix,
            availability: tuikitWidgetAvailability
        ),
        generatorSymbol(
            id: "s:TUIkit.Gadget",
            moduleName: "TUIkit",
            name: "gadget"
        ),
        generatorSymbol(
            id: "s:TUIkit.TerminalOnly",
            moduleName: "TUIkit",
            name: "terminalOnly"
        ),
    ]
    if includeAmbiguousWidget {
        tuikitSymbols.append(
            generatorSymbol(
                id: "s:TUIkit.WidgetAlias",
                moduleName: "TUIkit",
                name: "widget"
            )
        )
    }
    let tuikitSet = try makeSet(
        name: "TUIkit",
        sources: [
            sourceFixture(
                id: "tuikit-macos",
                moduleName: "TUIkit",
                symbols: tuikitSymbols
            ),
        ]
    )
    return GeneratorFixture(referenceSet: referenceSet, tuikitSet: tuikitSet)
}

func reviewedWidgetOverride(
    allowedDifferences: [CompatibilityDifference]
) -> TUIkitReviewOverride {
    TUIkitReviewOverride(
        symbolID: "s:TUIkit.Widget",
        action: .mapReviewedException,
        referenceID: "s:SwiftUI.Widget",
        exception: CompatibilityException(
            kind: .terminal,
            reason: "The terminal implementation requires this reviewed signature difference.",
            allowedDifferences: allowedDifferences
        )
    )
}
