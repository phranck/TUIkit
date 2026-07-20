//  🖥️ TUIKit — Terminal UI Kit for Swift
//  KeyedCollectionRuntimeTests.swift
//
//  License: MIT

import Foundation
import Observation
import Testing
import TUIkitTestSupport

@testable import TUIkit

@MainActor
@Suite("Keyed Collection Runtime", .serialized)
struct KeyedCollectionRuntimeTests {
    @Test("ForEach renders each element inside a stack")
    func forEachRendersEachElement() {
        let harness = RuntimeCharacterizationHarness()
        let actualLines = harness.render {
            VStack {
                ForEach(0..<2) { index in
                    Text("row:\(index)")
                }
            }
        }.ansiStrippedLines

        #expect(actualLines == ["row:0", "row:1"])
    }

    @Test("ForEach State follows IDs across insertion, reorder, and removal")
    func forEachStateFollowsIDs() {
        let harness = RuntimeCharacterizationHarness()

        let initial = harness.render {
            VStack {
                ForEach([1, 2], id: \.self) { id in
                    StatefulForEachRow(id: id)
                }
            }
        }
        let inserted = harness.render {
            VStack {
                ForEach([3, 1, 2], id: \.self) { id in
                    StatefulForEachRow(id: id)
                }
            }
        }
        let reordered = harness.render {
            VStack {
                ForEach([2, 1], id: \.self) { id in
                    StatefulForEachRow(id: id)
                }
            }
        }
        let removed = harness.render {
            VStack {
                ForEach([2], id: \.self) { id in
                    StatefulForEachRow(id: id)
                }
            }
        }

        #expect(initial.ansiStrippedLines == ["1:1", "2:2"])
        #expect(inserted.ansiStrippedLines == ["3:3", "1:1", "2:2"])
        #expect(reordered.ansiStrippedLines == ["2:2", "1:1"])
        #expect(removed.ansiStrippedLines == ["2:2"])
        #expect(harness.storedStateCount == 1)
    }

    @Test("ForEach lifecycle follows IDs across insertion, reorder, and removal")
    func forEachLifecycleFollowsIDs() {
        let harness = RuntimeCharacterizationHarness()
        let trace = harness.trace

        _ = harness.render {
            VStack {
                ForEach([1, 2], id: \.self) { id in
                    KeyedLifecycleRow(id: id, trace: trace)
                }
            }
        }
        _ = harness.render {
            VStack {
                ForEach([3, 2, 1], id: \.self) { id in
                    KeyedLifecycleRow(id: id, trace: trace)
                }
            }
        }

        #expect(trace.snapshot().filter { $0 == .lifecycle("appear:1") }.count == 1)
        #expect(trace.snapshot().filter { $0 == .lifecycle("appear:2") }.count == 1)
        #expect(trace.snapshot().filter { $0 == .lifecycle("appear:3") }.count == 1)
        #expect(trace.snapshot().contains(.lifecycle("disappear:1")) == false)
        #expect(trace.snapshot().contains(.lifecycle("disappear:2")) == false)
        #expect(trace.snapshot().contains(.lifecycle("disappear:3")) == false)

        _ = harness.render {
            VStack {
                ForEach([2], id: \.self) { id in
                    KeyedLifecycleRow(id: id, trace: trace)
                }
            }
        }

        #expect(trace.snapshot().filter { $0 == .lifecycle("disappear:1") }.count == 1)
        #expect(trace.snapshot().filter { $0 == .lifecycle("disappear:3") }.count == 1)
        #expect(trace.snapshot().contains(.lifecycle("disappear:2")) == false)
        #expect(harness.mountedLifecycleCallbackCount == 1)
    }

    @Test("ForEach focus follows IDs across insertion, reorder, and removal")
    func forEachFocusFollowsIDs() {
        let harness = RuntimeCharacterizationHarness()
        let trace = harness.trace

        _ = harness.render {
            HStack {
                ForEach([1, 2], id: \.self) { id in
                    Button("Item \(id)") {
                        trace.record(.effect("activate:\(id)"))
                    }
                }
            }
        }
        #expect(harness.dispatchFocusEvent(KeyEvent(key: .tab)))
        let focusedItemTwo = harness.currentFocusedID
        let initialStateIdentities = Set(harness.storedStateIdentityPaths)

        _ = harness.render {
            HStack {
                ForEach([3, 2, 1], id: \.self) { id in
                    Button("Item \(id)") {
                        trace.record(.effect("activate:\(id)"))
                    }
                }
            }
        }

        #expect(focusedItemTwo != nil)
        #expect(harness.currentFocusedID == focusedItemTwo)
        let insertedStateIdentities = Set(harness.storedStateIdentityPaths)
        #expect(initialStateIdentities.isSubset(of: insertedStateIdentities))
        #expect(harness.dispatchFocusEvent(KeyEvent(key: .enter)))
        #expect(trace.snapshot().contains(.effect("activate:2")))

        _ = harness.render {
            HStack {
                ForEach([1], id: \.self) { id in
                    Button("Item \(id)") {
                        trace.record(.effect("activate:\(id)"))
                    }
                }
            }
        }

        #expect(harness.currentFocusedID != focusedItemTwo)
        #expect(harness.storedStateCount < insertedStateIdentities.count)
        #expect(Set(harness.storedStateIdentityPaths).isSubset(of: insertedStateIdentities))
    }

    @Test("ForEach tasks follow inserted IDs and cancel removed items", .timeLimit(.minutes(1)))
    func forEachTasksFollowIDs() async {
        let harness = RuntimeCharacterizationHarness()
        let trace = harness.trace
        let first = KeyedTaskItem(id: 1)
        let second = KeyedTaskItem(id: 2)
        let third = KeyedTaskItem(id: 3)

        _ = harness.render {
            VStack {
                ForEach([first, second]) { item in
                    KeyedTaskRow(item: item, trace: trace)
                }
            }
        }
        await first.started.wait()
        await second.started.wait()

        _ = harness.render {
            VStack {
                ForEach([third, second, first]) { item in
                    KeyedTaskRow(item: item, trace: trace)
                }
            }
        }
        await third.started.wait()

        #expect(trace.snapshot().filter { $0 == .task("start:1") }.count == 1)
        #expect(trace.snapshot().filter { $0 == .task("start:2") }.count == 1)
        #expect(trace.snapshot().filter { $0 == .task("start:3") }.count == 1)
        #expect(harness.mountedTaskCount == 3)

        _ = harness.render {
            VStack {
                ForEach([second]) { item in
                    KeyedTaskRow(item: item, trace: trace)
                }
            }
        }
        await first.cancelled.wait()
        await third.cancelled.wait()

        #expect(trace.snapshot().filter { $0 == .task("cancel:1") }.count == 1)
        #expect(trace.snapshot().filter { $0 == .task("cancel:3") }.count == 1)
        #expect(trace.snapshot().contains(.task("cancel:2")) == false)
        #expect(harness.mountedTaskCount == 1)

        harness.unmount()
        await second.cancelled.wait()

        #expect(harness.mountedTaskCount == 0)
    }

    @Test("ForEach Observation follows inserted IDs and releases removed items")
    func forEachObservationFollowsIDs() {
        let harness = RuntimeCharacterizationHarness()
        let first = ObservedForEachItem(id: 1)
        let second = ObservedForEachItem(id: 2)
        let third = ObservedForEachItem(id: 3)

        _ = harness.render {
            VStack {
                ForEach([first, second]) { item in
                    ObservedForEachRow(item: item)
                }
            }
        }
        let initialRegistrationCount = harness.observationRegistrationCount
        first.model.value = 1
        let initialInvalidations = harness.consumePendingSubtreeInvalidations()

        #expect(initialInvalidations.count == 1)

        _ = harness.render {
            VStack {
                ForEach([third, second, first]) { item in
                    ObservedForEachRow(item: item)
                }
            }
        }
        first.model.value = 2
        let reorderedInvalidations = harness.consumePendingSubtreeInvalidations()

        #expect(harness.observationRegistrationCount == initialRegistrationCount + 1)
        #expect(reorderedInvalidations == initialInvalidations)

        _ = harness.render {
            VStack {
                ForEach([second]) { item in
                    ObservedForEachRow(item: item)
                }
            }
        }
        let remainingRegistrationCount = harness.observationRegistrationCount
        first.model.value = 3
        third.model.value = 1

        #expect(remainingRegistrationCount < initialRegistrationCount)
        #expect(harness.consumePendingSubtreeInvalidations().isEmpty)

        second.model.value = 1
        #expect(harness.consumePendingSubtreeInvalidations().count == 1)
    }

    @Test("List row State follows ForEach IDs")
    func listRowStateFollowsForEachIDs() {
        let harness = RuntimeCharacterizationHarness()
        var selection: Int?

        let initial = harness.render {
            List(selection: Binding(get: { selection }, set: { selection = $0 })) {
                ForEach([1, 2], id: \.self) { id in
                    StatefulForEachRow(id: id)
                }
            }
        }.ansiStrippedLines.joined(separator: "\n")
        let reordered = harness.render {
            List(selection: Binding(get: { selection }, set: { selection = $0 })) {
                ForEach([2, 1], id: \.self) { id in
                    StatefulForEachRow(id: id)
                }
            }
        }.ansiStrippedLines.joined(separator: "\n")

        #expect(initial.contains("1:1"))
        #expect(initial.contains("2:2"))
        #expect(reordered.contains("2:2"))
        #expect(reordered.contains("1:1"))
    }

    @Test("ForEach reports duplicate IDs deterministically")
    func forEachReportsDuplicateIDs() {
        let harness = RuntimeCharacterizationHarness()
        let items = duplicateItems

        let snapshot = harness.render {
            VStack {
                ForEach(items) { item in
                    Text(item.label)
                }
            }
        }

        let renderedLines = snapshot.ansiStrippedLines.map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        #expect(renderedLines == ["First", "Second", "Third"])
        expectDuplicateDiagnostic(in: harness, container: "ForEach")
    }

    @Test("Table reports duplicate IDs deterministically")
    func tableReportsDuplicateIDs() {
        let harness = RuntimeCharacterizationHarness()
        var selection: String?

        let snapshot = harness.render {
            Table(
                duplicateItems,
                selection: Binding(get: { selection }, set: { selection = $0 })
            ) {
                TableColumn("Label", value: \DuplicateForEachItem.label)
            }
        }

        let rendered = snapshot.ansiStrippedLines.joined(separator: "\n")
        #expect(rendered.contains("First"))
        #expect(rendered.contains("Second"))
        #expect(rendered.contains("Third"))
        expectDuplicateDiagnostic(in: harness, container: "Table")
    }
}

// MARK: - Helpers

@MainActor
private func expectDuplicateDiagnostic(
    in harness: RuntimeCharacterizationHarness,
    container: String
) {
    let message = harness.currentDiagnosticMessages.first ?? ""
    #expect(harness.currentDiagnosticMessages.count == 1)
    #expect(message.contains(container))
    #expect(message.contains("duplicate"))
    #expect(message.contains("0, 2"))
}

private let duplicateItems = [
    DuplicateForEachItem(id: "duplicate", label: "First"),
    DuplicateForEachItem(id: "unique", label: "Second"),
    DuplicateForEachItem(id: "duplicate", label: "Third"),
]

// MARK: - Fixtures

private struct StatefulForEachRow: View {
    @State private var storedID = 0

    let id: Int

    var body: some View {
        if storedID == 0 {
            storedID = id
        }
        return Text("\(id):\(storedID)")
    }
}

private struct DuplicateForEachItem: Identifiable, Sendable {
    let id: String
    let label: String
}

private struct KeyedTaskItem: Identifiable, Sendable {
    let id: Int
    let started = AsyncSignal()
    let cancelled = AsyncSignal()
}

private struct KeyedLifecycleRow: View {
    let id: Int
    let trace: TraceRecorder<RuntimeTraceEvent>

    var body: some View {
        Text("\(id)")
            .onAppear {
                trace.record(.lifecycle("appear:\(id)"))
            }
            .onDisappear {
                trace.record(.lifecycle("disappear:\(id)"))
            }
    }
}

private struct KeyedTaskRow: View {
    let item: KeyedTaskItem
    let trace: TraceRecorder<RuntimeTraceEvent>

    var body: some View {
        Text("task:\(item.id)")
            .task {
                trace.record(.task("start:\(item.id)"))
                item.started.signal()

                await withTaskCancellationHandler {
                    try? await Task.sleep(nanoseconds: UInt64.max)
                } onCancel: {
                    trace.record(.task("cancel:\(item.id)"))
                    item.cancelled.signal()
                }
            }
    }
}

private struct ObservedForEachItem: Identifiable {
    let id: Int
    let model = KeyedObservationModel()
}

private struct ObservedForEachRow: View {
    let item: ObservedForEachItem

    var body: some View {
        Text("\(item.id):\(item.model.value)")
    }
}

@Observable
private final class KeyedObservationModel {
    var value = 0
}
