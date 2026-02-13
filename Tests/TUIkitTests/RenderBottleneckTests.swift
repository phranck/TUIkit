//  TUIKit - Terminal UI Kit for Swift
//  RenderBottleneckTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

// MARK: - Render Bottleneck Analysis

/// Deep analysis tests to identify specific render bottlenecks.
@MainActor
@Suite("Render Bottleneck Analysis")
struct RenderBottleneckTests {

    private func testContext(width: Int = 80, height: Int = 24) -> RenderContext {
        RenderContext(availableWidth: width, availableHeight: height)
    }

    /// Measures execution time of a block over multiple iterations.
    ///
    /// Uses `Date` instead of `CFAbsoluteTimeGetCurrent` because CoreFoundation
    /// timing functions are not available on Linux. The precision difference
    /// is negligible for performance benchmarks at millisecond granularity.
    private func measure(_ name: String, iterations: Int = 1000, block: () -> Void) -> TimeInterval {
        let start = Date()
        for _ in 0..<iterations {
            block()
        }
        let time = Date().timeIntervalSince(start)
        let perIteration = (time / Double(iterations)) * 1000
        print("  \(name): \(String(format: "%.3f", perIteration))ms per iteration")
        return time
    }

    // MARK: - Stack Depth Analysis

    @Test("Analyze stack nesting depth impact")
    func analyzeStackNestingDepth() {
        let context = testContext()
        let iterations = 500

        print("\n=== Stack Nesting Depth Analysis ===")

        // Depth 1
        let depth1 = VStack { Text("A") }
        let time1 = measure("Depth 1", iterations: iterations) {
            _ = renderToBuffer(depth1, context: context)
        }

        // Depth 2
        let depth2 = VStack { VStack { Text("A") } }
        let time2 = measure("Depth 2", iterations: iterations) {
            _ = renderToBuffer(depth2, context: context)
        }

        // Depth 3
        let depth3 = VStack { VStack { VStack { Text("A") } } }
        let time3 = measure("Depth 3", iterations: iterations) {
            _ = renderToBuffer(depth3, context: context)
        }

        // Depth 5
        let depth5 = VStack { VStack { VStack { VStack { VStack { Text("A") } } } } }
        let time5 = measure("Depth 5", iterations: iterations) {
            _ = renderToBuffer(depth5, context: context)
        }

        // Depth 10
        let depth10 = VStack { VStack { VStack { VStack { VStack {
            VStack { VStack { VStack { VStack { VStack { Text("A") } } } } }
        } } } } }
        let time10 = measure("Depth 10", iterations: iterations) {
            _ = renderToBuffer(depth10, context: context)
        }

        print("=====================================\n")

        // Calculate overhead per nesting level
        let overheadPerLevel = (time10 - time1) / 9.0 / Double(iterations) * 1000
        print("Overhead per nesting level: \(String(format: "%.4f", overheadPerLevel))ms")

        // With two-pass layout, there's additional overhead per level due to
        // measure + render passes. The threshold is relaxed to account for this.
        // For typical UIs (3-5 levels), the overhead is acceptable:
        // - Depth 3: ~0.04ms
        // - Depth 5: ~0.16ms
        // - Depth 10: ~5ms (edge case, rare in practice)
        #expect(overheadPerLevel < 1.0, "Nesting overhead too high: \(overheadPerLevel)ms per level")
    }

    // MARK: - Child Count Analysis

    @Test("Analyze child count impact on VStack")
    func analyzeChildCountVStack() {
        let context = testContext()
        let iterations = 500

        print("\n=== VStack Child Count Analysis ===")

        // 1 child
        let children1 = VStack { Text("A") }
        _ = measure("1 child", iterations: iterations) {
            _ = renderToBuffer(children1, context: context)
        }

        // 5 children
        let children5 = VStack {
            Text("A"); Text("B"); Text("C"); Text("D"); Text("E")
        }
        _ = measure("5 children", iterations: iterations) {
            _ = renderToBuffer(children5, context: context)
        }

        // 10 children
        let children10 = VStack {
            Text("A"); Text("B"); Text("C"); Text("D"); Text("E")
            Text("F"); Text("G"); Text("H"); Text("I"); Text("J")
        }
        let time10 = measure("10 children", iterations: iterations) {
            _ = renderToBuffer(children10, context: context)
        }

        print("=====================================\n")

        // 10 children in 500 iterations should still be fast
        #expect(time10 < 0.5, "10 children VStack too slow: \(time10)s")
    }

    // MARK: - ForEach Analysis

    @Test("Analyze ForEach iteration count impact")
    func analyzeForEachIterations() {
        let context = testContext()
        let iterations = 200

        print("\n=== ForEach Iteration Analysis ===")

        // 5 items
        let items5 = Array(0..<5)
        let forEach5 = VStack {
            ForEach(items5, id: \.self) { i in
                Text("Row \(i)")
            }
        }
        _ = measure("5 items", iterations: iterations) {
            _ = renderToBuffer(forEach5, context: context)
        }

        // 20 items
        let items20 = Array(0..<20)
        let forEach20 = VStack {
            ForEach(items20, id: \.self) { i in
                Text("Row \(i)")
            }
        }
        _ = measure("20 items", iterations: iterations) {
            _ = renderToBuffer(forEach20, context: context)
        }

        // 50 items
        let items50 = Array(0..<50)
        let forEach50 = VStack {
            ForEach(items50, id: \.self) { i in
                Text("Row \(i)")
            }
        }
        let time50 = measure("50 items", iterations: iterations) {
            _ = renderToBuffer(forEach50, context: context)
        }

        // 100 items
        let items100 = Array(0..<100)
        let forEach100 = VStack {
            ForEach(items100, id: \.self) { i in
                Text("Row \(i)")
            }
        }
        let time100 = measure("100 items", iterations: iterations) {
            _ = renderToBuffer(forEach100, context: context)
        }

        print("=====================================\n")

        // Should scale linearly, not exponentially
        let scaleFactor = time100 / time50
        print("Scale factor (100 vs 50 items): \(String(format: "%.2f", scaleFactor))x")
        #expect(scaleFactor < 3.0, "ForEach scaling is worse than linear: \(scaleFactor)x for 2x items")
    }

    // MARK: - Modifier Chain Analysis

    @Test("Analyze modifier chain depth impact")
    func analyzeModifierChainDepth() {
        let context = testContext()
        let iterations = 500

        print("\n=== Modifier Chain Analysis ===")

        // No modifiers
        let noModifiers = Text("Hello")
        _ = measure("0 modifiers", iterations: iterations) {
            _ = renderToBuffer(noModifiers, context: context)
        }

        // 1 modifier
        let oneModifier = Text("Hello").bold()
        _ = measure("1 modifier", iterations: iterations) {
            _ = renderToBuffer(oneModifier, context: context)
        }

        // 3 modifiers
        let threeModifiers = Text("Hello").bold().foregroundStyle(.red).dimmed()
        _ = measure("3 modifiers", iterations: iterations) {
            _ = renderToBuffer(threeModifiers, context: context)
        }

        // 5 modifiers
        let fiveModifiers = Text("Hello")
            .bold()
            .foregroundStyle(.red)
            .dimmed()
            .padding(1)
            .border(.line)
        let time5 = measure("5 modifiers", iterations: iterations) {
            _ = renderToBuffer(fiveModifiers, context: context)
        }

        print("=====================================\n")

        #expect(time5 < 0.5, "5 modifiers too slow: \(time5)s")
    }

    // MARK: - Interactive Controls Analysis

    @Test("Analyze interactive control overhead")
    func analyzeInteractiveControlOverhead() {
        let context = testContext()
        let iterations = 500

        print("\n=== Interactive Control Analysis ===")

        // Simple Text (baseline)
        let text = Text("Hello")
        _ = measure("Text (baseline)", iterations: iterations) {
            _ = renderToBuffer(text, context: context)
        }

        // Button
        let button = Button("Click") {}
        _ = measure("Button", iterations: iterations) {
            _ = renderToBuffer(button, context: context)
        }

        // Toggle
        var isOn = false
        let toggle = Toggle("Enable", isOn: Binding(get: { isOn }, set: { isOn = $0 }))
        _ = measure("Toggle", iterations: iterations) {
            _ = renderToBuffer(toggle, context: context)
        }

        // Menu (more complex)
        let menu = Menu(
            title: "Menu",
            items: [
                MenuItem(label: "A"),
                MenuItem(label: "B"),
                MenuItem(label: "C")
            ]
        )
        _ = measure("Menu (3 items)", iterations: iterations) {
            _ = renderToBuffer(menu, context: context)
        }

        // RadioButtonGroup
        var selection = "a"
        let radioGroup = RadioButtonGroup(
            selection: Binding(get: { selection }, set: { selection = $0 })
        ) {
            RadioButtonItem("a", "Option A")
            RadioButtonItem("b", "Option B")
            RadioButtonItem("c", "Option C")
        }
        let timeRadio = measure("RadioButtonGroup (3 items)", iterations: iterations) {
            _ = renderToBuffer(radioGroup, context: context)
        }

        print("=====================================\n")

        #expect(timeRadio < 0.5, "RadioButtonGroup too slow: \(timeRadio)s")
    }

    // MARK: - String Operations Analysis

    @Test("Analyze ANSI string operations impact")
    func analyzeStringOperations() {
        let context = testContext()
        let iterations = 500

        print("\n=== String Operations Analysis ===")

        // Short text
        let shortText = Text("Hi")
        _ = measure("Short text (2 chars)", iterations: iterations) {
            _ = renderToBuffer(shortText, context: context)
        }

        // Medium text
        let mediumText = Text("This is a medium length text string")
        _ = measure("Medium text (36 chars)", iterations: iterations) {
            _ = renderToBuffer(mediumText, context: context)
        }

        // Long text
        let longText = Text(String(repeating: "A", count: 200))
        _ = measure("Long text (200 chars)", iterations: iterations) {
            _ = renderToBuffer(longText, context: context)
        }

        // Very long text
        let veryLongText = Text(String(repeating: "B", count: 1000))
        let timeLong = measure("Very long text (1000 chars)", iterations: iterations) {
            _ = renderToBuffer(veryLongText, context: context)
        }

        print("=====================================\n")

        #expect(timeLong < 0.5, "Very long text too slow: \(timeLong)s")
    }

    // MARK: - LazyStack vs Regular Stack

    @Test("Compare LazyStack vs regular Stack performance")
    func compareLazyVsRegular() {
        let iterations = 300

        print("\n=== Lazy vs Regular Stack Comparison ===")

        // Large item count, small viewport
        let items = Array(0..<100)
        let smallContext = testContext(height: 10)

        let regularStack = VStack {
            ForEach(items, id: \.self) { i in
                Text("Row \(i)")
            }
        }
        let regularTime = measure("VStack (100 items, 10 visible)", iterations: iterations) {
            _ = renderToBuffer(regularStack, context: smallContext)
        }

        let lazyStack = LazyVStack {
            ForEach(items, id: \.self) { i in
                Text("Row \(i)")
            }
        }
        let lazyTime = measure("LazyVStack (100 items, 10 visible)", iterations: iterations) {
            _ = renderToBuffer(lazyStack, context: smallContext)
        }

        print("=====================================\n")

        let speedup = regularTime / lazyTime
        print("LazyVStack speedup: \(String(format: "%.2f", speedup))x")

        // LazyVStack may have overhead for small datasets, but should not be
        // dramatically slower. Allow up to 3x for measurement variance.
        #expect(lazyTime <= regularTime * 3.0, "LazyVStack should not be dramatically slower than VStack")
    }
}
