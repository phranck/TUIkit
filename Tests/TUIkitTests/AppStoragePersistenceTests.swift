//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AppStoragePersistenceTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

@Suite("AppStorage Persistence")
struct AppStoragePersistenceTests {

    // MARK: - Ordered Writer

    @Test("Each mutation persists its own snapshot in mutation order")
    func mutationsPersistOrderedSnapshots() {
        let recorder = PersistRecorder(delayFirstWrite: 0.05)
        let storage = JSONFileStorage(
            fileURL: temporaryStorageURL(),
            persist: recorder.persist
        )

        storage.setValue("first", forKey: "key")
        storage.setValue("second", forKey: "key")
        storage.synchronize()

        let snapshots = recorder.recordedSnapshots()
        #expect(snapshots.count == 2)
        #expect(snapshots.first?["key"] == "first")
        #expect(snapshots.last?["key"] == "second")
    }

    @Test("synchronize awaits every previously issued write")
    func synchronizeAwaitsAllPreviousWrites() {
        let recorder = PersistRecorder(delayPerWrite: 0.05)
        let storage = JSONFileStorage(
            fileURL: temporaryStorageURL(),
            persist: recorder.persist
        )

        storage.setValue("one", forKey: "a")
        storage.setValue("two", forKey: "b")
        storage.removeValue(forKey: "a")
        storage.synchronize()

        let snapshots = recorder.recordedSnapshots()
        #expect(snapshots.count == 3)
        #expect(snapshots.last?["a"] == nil)
        #expect(snapshots.last?["b"] == "two")
    }

    // MARK: - Restart

    @Test("A restarted storage reads previously persisted values")
    func restartReadsPersistedValues() {
        let fileURL = temporaryStorageURL()
        defer { removeTemporaryStorage(fileURL) }

        let first = JSONFileStorage(fileURL: fileURL)
        first.setValue("persisted", forKey: "greeting")
        first.setValue(42, forKey: "answer")
        first.synchronize()

        let second = JSONFileStorage(fileURL: fileURL)
        let greeting: String? = second.value(forKey: "greeting")
        let answer: Int? = second.value(forKey: "answer")
        #expect(greeting == "persisted")
        #expect(answer == 42)
    }

    // MARK: - Corruption

    @Test("A corrupted storage file starts fresh and recovers on write")
    func corruptedFileStartsFreshAndRecovers() throws {
        let fileURL = temporaryStorageURL()
        defer { removeTemporaryStorage(fileURL) }
        try Data("not { valid json".utf8).write(to: fileURL)

        let storage = JSONFileStorage(fileURL: fileURL)
        let missing: String? = storage.value(forKey: "key")
        #expect(missing == nil)

        storage.setValue("recovered", forKey: "key")
        storage.synchronize()

        let reloaded = JSONFileStorage(fileURL: fileURL)
        let value: String? = reloaded.value(forKey: "key")
        #expect(value == "recovered")
    }

    // MARK: - Failure Reporting

    @Test("A failing write reports a sanitized persistence failure")
    func failingWriteReportsPersistenceFailure() {
        let fileURL = temporaryStorageURL()
        let reported = ReportedFailures()
        let storage = JSONFileStorage(
            fileURL: fileURL,
            persist: { _, _ in throw CocoaError(.fileWriteNoPermission) },
            onPersistenceFailure: { reported.append($0) }
        )

        storage.setValue("value", forKey: "key")
        storage.synchronize()

        let failures = reported.all()
        #expect(failures.count == 1)
        #expect(failures.first?.operation == .write)
        #expect(failures.first?.description.contains(fileURL.path) == false)
    }

    @Test("The default persistence step reports unwritable destinations without leaking the path")
    func unwritableDestinationReportsFailure() {
        let missingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("tuikit-missing-\(UUID().uuidString)")
        let fileURL = missingDirectory.appendingPathComponent("settings.json")
        let reported = ReportedFailures()
        let storage = JSONFileStorage(
            fileURL: fileURL,
            onPersistenceFailure: { reported.append($0) }
        )

        storage.setValue("value", forKey: "key")
        storage.synchronize()

        let failures = reported.all()
        #expect(failures.isEmpty == false)
        #expect(failures.allSatisfy { failure in
            !failure.description.contains(missingDirectory.path)
                && !failure.reason.contains(missingDirectory.path)
        })
    }

    @Test("An encoding failure is reported instead of silently dropped")
    func encodingFailureIsReported() {
        let reported = ReportedFailures()
        let storage = JSONFileStorage(
            fileURL: temporaryStorageURL(),
            persist: { _, _ in },
            onPersistenceFailure: { reported.append($0) }
        )

        storage.setValue(FailingEncodable(), forKey: "key")
        storage.synchronize()

        let failures = reported.all()
        #expect(failures.count == 1)
        #expect(failures.first?.operation == .encode)
    }

    // MARK: - Concurrency Stress

    @Test("Concurrent mutations never lose the final value per key", .timeLimit(.minutes(1)))
    func concurrentMutationsSurviveStress() async {
        let fileURL = temporaryStorageURL()
        defer { removeTemporaryStorage(fileURL) }
        let storage = JSONFileStorage(fileURL: fileURL)
        let writers = 16
        let mutationsPerWriter = 25

        await withTaskGroup(of: Void.self) { group in
            for writer in 0..<writers {
                group.addTask {
                    for mutation in 0..<mutationsPerWriter {
                        storage.setValue(mutation, forKey: "writer-\(writer)")
                        if mutation.isMultiple(of: 10) {
                            storage.synchronize()
                        }
                    }
                }
            }
        }
        storage.synchronize()

        let reloaded = JSONFileStorage(fileURL: fileURL)
        for writer in 0..<writers {
            let value: Int? = reloaded.value(forKey: "writer-\(writer)")
            #expect(value == mutationsPerWriter - 1)
        }
    }
}

// MARK: - Test Support

/// Collects persistence failures reported by a storage under test.
private final class ReportedFailures: @unchecked Sendable {
    /// Reported failures in delivery order.
    private var failures: [StoragePersistenceError] = []

    /// Lock protecting the failure list.
    private let lock = NSLock()

    /// Records one reported failure.
    func append(_ failure: StoragePersistenceError) {
        lock.lock()
        failures.append(failure)
        lock.unlock()
    }

    /// Returns every failure reported so far.
    func all() -> [StoragePersistenceError] {
        lock.lock()
        defer { lock.unlock() }
        return failures
    }
}

/// A Codable value whose encoding always fails.
private struct FailingEncodable: Codable {
    init() {}

    init(from decoder: Decoder) throws {
        self.init()
    }

    func encode(to encoder: Encoder) throws {
        throw EncodingError.invalidValue(
            self,
            EncodingError.Context(codingPath: [], debugDescription: "always fails")
        )
    }
}

/// Records every payload handed to the storage's persist step.
///
/// Optional artificial delays surface ordering bugs: a delayed first write
/// must not land after (and thereby overwrite) a later snapshot.
private final class PersistRecorder: @unchecked Sendable {
    /// Serialized JSON payloads in the order they were persisted.
    private var payloads: [Data] = []

    /// Lock protecting recorded payloads.
    private let lock = NSLock()

    /// Delay applied to the first write only.
    private let delayFirstWrite: TimeInterval

    /// Delay applied to every write.
    private let delayPerWrite: TimeInterval

    /// Number of persist invocations seen so far.
    private var invocations = 0

    /// Creates a recorder with optional artificial write delays.
    init(delayFirstWrite: TimeInterval = 0, delayPerWrite: TimeInterval = 0) {
        self.delayFirstWrite = delayFirstWrite
        self.delayPerWrite = delayPerWrite
    }

    /// The persist closure to inject into `JSONFileStorage`.
    var persist: @Sendable (Data, URL) throws -> Void {
        { [self] payload, _ in
            lock.lock()
            invocations += 1
            let isFirst = invocations == 1
            lock.unlock()

            if isFirst, delayFirstWrite > 0 {
                Thread.sleep(forTimeInterval: delayFirstWrite)
            }
            if delayPerWrite > 0 {
                Thread.sleep(forTimeInterval: delayPerWrite)
            }

            lock.lock()
            payloads.append(payload)
            lock.unlock()
        }
    }

    /// Returns every recorded payload decoded into `[key: decoded String or Int]`.
    ///
    /// Values are stored as base64-encoded JSON fragments; this decodes them
    /// back to their readable representation for assertions.
    func recordedSnapshots() -> [[String: String]] {
        lock.lock()
        defer { lock.unlock() }
        return payloads.map { payload in
            guard
                let object = try? JSONSerialization.jsonObject(with: payload),
                let encoded = object as? [String: String]
            else { return [:] }

            var snapshot: [String: String] = [:]
            for (key, base64) in encoded {
                guard
                    let data = Data(base64Encoded: base64),
                    let value = try? JSONDecoder().decode(String.self, from: data)
                else { continue }
                snapshot[key] = value
            }
            return snapshot
        }
    }
}

/// Returns a unique storage file URL inside the system temporary directory.
private func temporaryStorageURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("tuikit-storage-tests-\(UUID().uuidString)")
        .appendingPathExtension("json")
}

/// Removes a temporary storage file created by a test.
private func removeTemporaryStorage(_ fileURL: URL) {
    try? FileManager.default.removeItem(at: fileURL)
}
