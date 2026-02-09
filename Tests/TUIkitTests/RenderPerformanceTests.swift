//  TUIKit - Terminal UI Kit for Swift
//  RenderPerformanceTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

// MARK: - Render Performance Tests

/// Performance tests to verify that the View Architecture refactor
/// (converting controls to `body: some View`) does not significantly
/// impact render performance.
///
/// These tests measure render time for various view hierarchies and
/// compare against baseline expectations.
@MainActor
@Suite("Render Performance Tests")
struct RenderPerformanceTests {

    // MARK: - Test Helpers

    private func testContext(width: Int = 80, height: Int = 24) -> RenderContext {
        RenderContext(availableWidth: width, availableHeight: height)
    }

    /// Measures the time to render a view multiple times.
    private func measureRenderTime<V: View>(
        _ view: V,
        iterations: Int = 100,
        context: RenderContext
    ) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = renderToBuffer(view, context: context)
        }
        let end = CFAbsoluteTimeGetCurrent()
        return end - start
    }

    // MARK: - Stack Performance Tests

    @Test("VStack render performance is acceptable")
    func vStackPerformance() {
        let view = VStack {
            Text("Line 1")
            Text("Line 2")
            Text("Line 3")
            Text("Line 4")
            Text("Line 5")
        }

        let context = testContext()
        let time = measureRenderTime(view, iterations: 1000, context: context)

        // Should render 1000 iterations in under 1 second
        #expect(time < 1.0, "VStack render took \(time)s for 1000 iterations - too slow")
    }

    @Test("HStack render performance is acceptable")
    func hStackPerformance() {
        let view = HStack {
            Text("A")
            Text("B")
            Text("C")
            Text("D")
            Text("E")
        }

        let context = testContext()
        let time = measureRenderTime(view, iterations: 1000, context: context)

        #expect(time < 1.0, "HStack render took \(time)s for 1000 iterations - too slow")
    }

    @Test("Nested stacks render performance is acceptable")
    func nestedStacksPerformance() {
        let view = VStack {
            HStack {
                Text("A")
                Text("B")
            }
            HStack {
                Text("C")
                Text("D")
            }
            HStack {
                Text("E")
                Text("F")
            }
        }

        let context = testContext()
        let time = measureRenderTime(view, iterations: 1000, context: context)

        #expect(time < 1.5, "Nested stacks render took \(time)s for 1000 iterations - too slow")
    }

    // MARK: - Interactive Control Performance Tests

    @Test("Button render performance is acceptable")
    func buttonPerformance() {
        let view = Button("Test Button") {}

        let context = testContext()
        let time = measureRenderTime(view, iterations: 1000, context: context)

        #expect(time < 1.0, "Button render took \(time)s for 1000 iterations - too slow")
    }

    @Test("Toggle render performance is acceptable")
    func togglePerformance() {
        var isOn = false
        let view = Toggle("Test Toggle", isOn: Binding(get: { isOn }, set: { isOn = $0 }))

        let context = testContext()
        let time = measureRenderTime(view, iterations: 1000, context: context)

        #expect(time < 1.0, "Toggle render took \(time)s for 1000 iterations - too slow")
    }

    @Test("Menu render performance is acceptable")
    func menuPerformance() {
        let view = Menu(
            title: "Test Menu",
            items: [
                MenuItem(label: "Item 1"),
                MenuItem(label: "Item 2"),
                MenuItem(label: "Item 3")
            ]
        )

        let context = testContext()
        let time = measureRenderTime(view, iterations: 500, context: context)

        #expect(time < 1.0, "Menu render took \(time)s for 500 iterations - too slow")
    }

    @Test("RadioButtonGroup render performance is acceptable")
    func radioButtonGroupPerformance() {
        var selection = "a"
        let view = RadioButtonGroup(
            selection: Binding(get: { selection }, set: { selection = $0 })
        ) {
            RadioButtonItem("a", "Option A")
            RadioButtonItem("b", "Option B")
            RadioButtonItem("c", "Option C")
        }

        let context = testContext()
        let time = measureRenderTime(view, iterations: 500, context: context)

        #expect(time < 1.0, "RadioButtonGroup render took \(time)s for 500 iterations - too slow")
    }

    // MARK: - LazyStack Performance Tests

    @Test("LazyVStack render performance is acceptable")
    func lazyVStackPerformance() {
        let view = LazyVStack {
            Text("Line 1")
            Text("Line 2")
            Text("Line 3")
            Text("Line 4")
            Text("Line 5")
        }

        let context = testContext()
        let time = measureRenderTime(view, iterations: 1000, context: context)

        #expect(time < 1.0, "LazyVStack render took \(time)s for 1000 iterations - too slow")
    }

    @Test("LazyHStack render performance is acceptable")
    func lazyHStackPerformance() {
        let view = LazyHStack {
            Text("A")
            Text("B")
            Text("C")
            Text("D")
            Text("E")
        }

        let context = testContext()
        let time = measureRenderTime(view, iterations: 1000, context: context)

        #expect(time < 1.0, "LazyHStack render took \(time)s for 1000 iterations - too slow")
    }

    // MARK: - Complex Hierarchy Performance Tests

    @Test("Complex view hierarchy render performance is acceptable")
    func complexHierarchyPerformance() {
        var isOn = false
        let view = VStack(spacing: 1) {
            Text("Header").bold()
            HStack {
                Button("OK") {}
                Button("Cancel") {}
            }
            Toggle("Enable", isOn: Binding(get: { isOn }, set: { isOn = $0 }))
            Text("Footer")
        }

        let context = testContext()
        let time = measureRenderTime(view, iterations: 500, context: context)

        #expect(time < 1.5, "Complex hierarchy render took \(time)s for 500 iterations - too slow")
    }

    @Test("Deeply nested hierarchy render performance is acceptable")
    func deeplyNestedPerformance() {
        let view = VStack {
            VStack {
                VStack {
                    HStack {
                        HStack {
                            Text("Deep")
                        }
                    }
                }
            }
        }

        let context = testContext()
        let time = measureRenderTime(view, iterations: 1000, context: context)

        #expect(time < 1.0, "Deeply nested hierarchy render took \(time)s for 1000 iterations - too slow")
    }

    // MARK: - Modifier Chain Performance Tests

    @Test("Modifier chain performance is acceptable")
    func modifierChainPerformance() {
        let view = Text("Styled Text")
            .foregroundStyle(.red)
            .bold()
            .padding(2)

        let context = testContext()
        let time = measureRenderTime(view, iterations: 1000, context: context)

        #expect(time < 1.0, "Modifier chain render took \(time)s for 1000 iterations - too slow")
    }

    // MARK: - Comparative Tests

    @Test("VStack vs LazyVStack performance comparison")
    func vstackVsLazyVstackComparison() {
        let regularStack = VStack {
            ForEach(0..<10, id: \.self) { i in
                Text("Row \(i)")
            }
        }

        let lazyStack = LazyVStack {
            ForEach(0..<10, id: \.self) { i in
                Text("Row \(i)")
            }
        }

        let context = testContext(height: 5) // Only 5 lines visible
        let regularTime = measureRenderTime(regularStack, iterations: 500, context: context)
        let lazyTime = measureRenderTime(lazyStack, iterations: 500, context: context)

        // LazyVStack may have overhead for small datasets due to truncation logic.
        // Allow up to 3x for measurement variance on small datasets.
        #expect(lazyTime <= regularTime * 3.0, "LazyVStack (\(lazyTime)s) should not be dramatically slower than VStack (\(regularTime)s)")
    }
}

// MARK: - Performance Statistics

@MainActor
@Suite("Render Performance Statistics")
struct RenderPerformanceStatistics {

    private func testContext(width: Int = 80, height: Int = 24) -> RenderContext {
        RenderContext(availableWidth: width, availableHeight: height)
    }

    @Test("Print render performance statistics")
    func printStatistics() {
        let context = testContext()
        let iterations = 1000

        var results: [(String, TimeInterval)] = []

        // Measure each view type
        let start1 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = renderToBuffer(VStack { Text("A"); Text("B") }, context: context)
        }
        results.append(("VStack (2 children)", CFAbsoluteTimeGetCurrent() - start1))

        let start2 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = renderToBuffer(HStack { Text("A"); Text("B") }, context: context)
        }
        results.append(("HStack (2 children)", CFAbsoluteTimeGetCurrent() - start2))

        let start3 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = renderToBuffer(Button("Test") {}, context: context)
        }
        results.append(("Button", CFAbsoluteTimeGetCurrent() - start3))

        var isOn = false
        let start4 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = renderToBuffer(Toggle("Test", isOn: Binding(get: { isOn }, set: { isOn = $0 })), context: context)
        }
        results.append(("Toggle", CFAbsoluteTimeGetCurrent() - start4))

        // Print results
        print("\n=== Render Performance Statistics ===")
        print("Iterations: \(iterations)")
        print("")
        for (name, time) in results {
            let perIteration = (time / Double(iterations)) * 1000 // ms
            print("\(name): \(String(format: "%.3f", time))s total, \(String(format: "%.3f", perIteration))ms per render")
        }
        print("=====================================\n")

        // All should complete in reasonable time
        for (name, time) in results {
            #expect(time < 2.0, "\(name) took too long: \(time)s")
        }
    }
}
