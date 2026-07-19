import Foundation

public struct BehaviorTestExecutionResults: Equatable, Sendable {
    public let discoveredTestIdentifiers: Set<String>
    public let successfulTestIdentifiers: Set<String>

    public init(
        discoveredTestIdentifiers: Set<String>,
        successfulTestIdentifiers: Set<String>
    ) {
        self.discoveredTestIdentifiers = discoveredTestIdentifiers
        self.successfulTestIdentifiers = successfulTestIdentifiers
    }
}

public struct BehaviorTestEventStreamLoader: Sendable {
    public init() {}

    public func load(from url: URL) throws -> BehaviorTestExecutionResults {
        let contents: String
        do {
            let data = try Data(contentsOf: url)
            guard let decoded = String(data: data, encoding: .utf8) else {
                throw EventStreamDecodingError.invalidUTF8
            }
            contents = decoded
        } catch {
            throw APICheckDiagnostic(
                code: "contract-test-results.read-failed",
                message: "Unable to read Swift test event stream \(url.lastPathComponent)"
            )
        }

        let records = try contents.split(whereSeparator: \.isNewline).enumerated().map { index, line in
            let record: EventStreamRecord
            do {
                record = try JSONDecoder().decode(
                    EventStreamRecord.self,
                    from: Data(line.utf8)
                )
            } catch {
                throw APICheckDiagnostic(
                    code: "contract-test-results.invalid-json",
                    message: "Swift test event stream line \(index + 1) is invalid"
                )
            }
            guard record.version == 0 else {
                throw APICheckDiagnostic(
                    code: "contract-test-results.version",
                    message: "Unsupported Swift test event stream version \(record.version)"
                )
            }
            return record
        }

        let functionIDs = try functionIdentifiers(in: records)
        var states = Dictionary(
            uniqueKeysWithValues: functionIDs.values.map {
                ($0, BehaviorTestState())
            }
        )
        for record in records where record.kind == "event" {
            guard let testID = record.payload.testID,
                  let stableID = stableIdentifier(for: testID, functionIDs: functionIDs)
            else { continue }
            switch record.payload.kind {
            case "issueRecorded", "testSkipped":
                states[stableID]?.invalid = true
            case "testStarted":
                states[stableID]?.started = true
            case "testEnded":
                states[stableID]?.endedSuccessfully = record.payload.messages?.contains {
                    $0.symbol == "pass"
                } == true
            default:
                break
            }
        }

        return BehaviorTestExecutionResults(
            discoveredTestIdentifiers: Set(states.keys),
            successfulTestIdentifiers: Set(states.compactMap { identifier, state in
                state.started && state.endedSuccessfully && !state.invalid
                    ? identifier
                    : nil
            })
        )
    }

    private func functionIdentifiers(
        in records: [EventStreamRecord]
    ) throws -> [String: String] {
        var identifiers: [String: String] = [:]
        var stableIdentifiers: Set<String> = []
        for record in records where record.kind == "test" && record.payload.kind == "function" {
            guard let fullID = record.payload.id,
                  let stableID = stableFunctionIdentifier(fullID),
                  identifiers[fullID] == nil,
                  stableIdentifiers.insert(stableID).inserted
            else {
                throw APICheckDiagnostic(
                    code: "contract-test-results.duplicate-test",
                    message: "Swift test event stream contains a duplicate function definition"
                )
            }
            identifiers[fullID] = stableID
        }
        return identifiers
    }

    private func stableFunctionIdentifier(_ fullID: String) -> String? {
        let components = fullID.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count >= 3,
              components.last?.contains(".swift:") == true
        else { return nil }
        return components.dropLast().joined(separator: "/")
    }

    private func stableIdentifier(
        for eventID: String,
        functionIDs: [String: String]
    ) -> String? {
        if let exact = functionIDs[eventID] {
            return exact
        }
        return functionIDs.keys.filter { eventID.hasPrefix("\($0)/") }
            .max { $0.count < $1.count }
            .flatMap { functionIDs[$0] }
    }
}

private struct EventStreamRecord: Decodable {
    let kind: String
    let payload: EventStreamPayload
    let version: Int
}

private struct EventStreamPayload: Decodable {
    let id: String?
    let kind: String?
    let messages: [EventStreamMessage]?
    let testID: String?
}

private struct EventStreamMessage: Decodable {
    let symbol: String
}

private struct BehaviorTestState {
    var started = false
    var endedSuccessfully = false
    var invalid = false
}

private enum EventStreamDecodingError: Error {
    case invalidUTF8
}
