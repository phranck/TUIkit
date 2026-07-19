# API Compatibility Gate

TUIkit tracks the public SwiftUI and TUIkit symbol inventories as an executable,
fail-closed compatibility manifest. The normative reference is SwiftUI from Xcode
26.6. TUIkit is evaluated with Swift 6.0.3 on macOS and Linux.

## Checked-in artifacts

- `Configuration/review-policy.json` contains the reviewed source decisions. Every
  reference symbol ID belongs to exactly one inclusion or exclusion rule, and every
  TUIkit symbol ID has an explicit override unless it has a unique exact mapping.
- `Configuration/compatibility-manifest.json` is generated from the policy and the
  current snapshot sets. Do not edit it by hand.
- `Configuration/owners.json` limits included APIs and TUIkit-only classifications
  to registered GitHub owner issues.
- `Configuration/contracts.json` links included APIs to executable compile
  contracts in `Configuration/CompileContracts/`.

The only supported exclusions are Apple representables, raster or GPU rendering,
touch or spatial input, and window-server features. An included symbol is either
`planned` with its intended TUIkit signature or `implemented` with a validated
one-to-one TUIkit mapping. Reviewed exceptions must state their exact allowed
surface differences.

## Reviewing a symbol change

1. Generate the Xcode 26.6 reference snapshots and Swift 6.0.3 TUIkit snapshots
   with the scripts used by CI, then assemble both snapshot sets.
2. Run `list-mapping-candidates` to inspect unique structural matches and all
   reported surface differences. This command never changes policy files.
3. Add each new reference ID to one reviewed policy rule. Assign included symbols
   to a registered owner issue and an executable contract. Add each new TUIkit ID
   as a reviewed mapping, a TUIkit-specific API, or an implementation leak.
4. Add or update positive and negative compile fixtures when a signature,
   generic constraint, argument label or order, result-builder rule, isolation
   boundary, conformance, or `Sendable` contract changes.
5. Generate the checked-in manifest and run the drift gate shown below.

Run these commands from the repository root:

```bash
API_BUILD_PATH=".build/api-compatibility"
API_TOOL="$(swift build \
  --package-path Tools/APICompatibility \
  --build-path "$API_BUILD_PATH" \
  --show-bin-path)/TUIkitAPICheck"

"$API_TOOL" generate-manifest \
  --policy Tools/APICompatibility/Configuration/review-policy.json \
  --owner-registry Tools/APICompatibility/Configuration/owners.json \
  --reference-set /path/to/reference/snapshot-set.json \
  --tuikit-set /path/to/tuikit/snapshot-set.json \
  --output Tools/APICompatibility/Configuration/compatibility-manifest.json

./scripts/verify-compatibility-manifest.sh \
  --tool "$API_TOOL" \
  --policy Tools/APICompatibility/Configuration/review-policy.json \
  --owner-registry Tools/APICompatibility/Configuration/owners.json \
  --reference-set /path/to/reference/snapshot-set.json \
  --tuikit-set /path/to/tuikit/snapshot-set.json \
  --contracts Tools/APICompatibility/Configuration/contracts.json \
  --manifest Tools/APICompatibility/Configuration/compatibility-manifest.json
```

The regular quality gate type-checks all compile contracts and validates the
registry against the Swift Testing event stream. CI additionally assembles both
platform snapshot sets and rejects missing decisions, stale generated output,
invalid mappings, unregistered contracts, and undeclared surface differences.
