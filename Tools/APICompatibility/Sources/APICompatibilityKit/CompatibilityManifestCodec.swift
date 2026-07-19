import Foundation

public struct CompatibilityManifestCodec: Sendable {
    public init() {}

    public func encode(_ manifest: CompatibilityManifest) throws -> Data {
        let canonical = canonicalized(manifest)
        if let diagnostic = ManifestValidator().validate(canonical).first {
            throw diagnostic
        }
        return try JSONArtifactCodec.encode(canonical)
    }

    public func write(_ manifest: CompatibilityManifest, to url: URL) throws {
        let data = try encode(manifest)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            throw APICheckDiagnostic(
                code: "manifest.write-failed",
                message: "Unable to write \(url.lastPathComponent)"
            )
        }
    }

    private func canonicalized(_ manifest: CompatibilityManifest) -> CompatibilityManifest {
        var canonical = manifest
        canonical.referenceIDs.sort()
        canonical.decisions.sort { $0.referenceID < $1.referenceID }
        for index in canonical.decisions.indices {
            canonical.decisions[index].evidence.sort {
                $0.kind.rawValue == $1.kind.rawValue
                    ? $0.reference < $1.reference
                    : $0.kind.rawValue < $1.kind.rawValue
            }
        }
        canonical.tuikitDecisions.sort { $0.symbolID < $1.symbolID }
        for index in canonical.tuikitDecisions.indices {
            canonical.tuikitDecisions[index].exception?.allowedDifferences.sort {
                $0.rawValue < $1.rawValue
            }
        }
        return canonical
    }
}
