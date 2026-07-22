//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewBuilderAlignmentTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("ViewBuilder SwiftUI Alignment")
struct ViewBuilderAlignmentTests {

    /// Creates an isolated render context for builder output assertions.
    private func testContext(width: Int = 40, height: Int = 10) -> RenderContext {
        RenderContext(
            availableWidth: width,
            availableHeight: height,
            tuiContext: TUIContext()
        )
    }

    // MARK: - Empty Block

    @Test("An empty builder block produces EmptyView")
    func emptyBuilderBlockProducesEmptyView() {
        // Swift 6.0 does not apply the builder transform to fully empty
        // bodies, so the zero-argument surface is asserted directly.
        let empty = ViewBuilder.buildBlock()

        #expect(type(of: empty) == EmptyView.self)
    }

    // MARK: - Tuple Blocks

    @Test("A multi-view block produces a tuple-typed TupleView")
    func multiViewBlockProducesTupleTypedTupleView() {
        struct Two: View {
            var body: some View {
                Text("a")
                Text("b")
            }
        }

        #expect(Two.Body.self == TupleView<(Text, Text)>.self)
    }

    @Test("TupleView exposes its children through value")
    func tupleViewExposesValue() {
        let tuple = TupleView((Text("a"), Text("b")))

        #expect(tuple.value.0 == Text("a"))
        #expect(tuple.value.1 == Text("b"))
    }

    @Test("A publicly constructed TupleView renders its children")
    func publicTupleInitRenders() {
        let tuple = TupleView((Text("first"), Text("second")))

        let buffer = renderToBuffer(tuple, context: testContext())

        #expect(buffer.lines.count == 2)
        #expect(buffer.lines[0].stripped == "first")
        #expect(buffer.lines[1].stripped == "second")
    }

    // MARK: - Runtime Equality

    @Test("TupleViews with equal comparable children compare as equal")
    func tupleEqualityForComparableChildren() {
        let first = TupleView((Text("same"), Text("same")))
        let second = TupleView((Text("same"), Text("same")))
        let different = TupleView((Text("same"), Text("changed")))

        #expect(first == second)
        #expect(first != different)
    }

    @Test("TupleViews with non-comparable children never compare as equal")
    func tupleEqualityFallsBackToNotEqual() {
        struct Uncomparable: View {
            let action: () -> Void
            var body: some View { Text("x") }
        }

        let view = TupleView((Text("a"), Uncomparable(action: {})))

        // swiftlint:disable:next identical_operands
        #expect(view != view)
    }

    // MARK: - Conditionals

    @Test("An if-else block produces _ConditionalContent")
    func ifElseProducesConditionalContent() {
        struct Cond: View {
            let flag: Bool
            var body: some View {
                if flag {
                    Text("yes")
                } else {
                    Spacer()
                }
            }
        }

        #expect(Cond.Body.self == _ConditionalContent<Text, Spacer>.self)

        let buffer = renderToBuffer(Cond(flag: true), context: testContext())
        #expect(buffer.lines.first?.stripped == "yes")
    }

    @Test("An if without else keeps optional content")
    func ifWithoutElseKeepsOptionalContent() {
        struct MaybeView: View {
            let flag: Bool
            var body: some View {
                if flag {
                    Text("shown")
                }
            }
        }

        #expect(MaybeView.Body.self == Text?.self)

        let shown = renderToBuffer(MaybeView(flag: true), context: testContext())
        #expect(shown.lines.first?.stripped == "shown")
    }

    // MARK: - Limited Availability

    @Test("Limited availability content is erased to AnyView")
    func limitedAvailabilityErasesToAnyView() {
        struct Available: View {
            var body: some View {
                if #available(macOS 10.15, *) {
                    Text("modern")
                }
            }
        }

        #expect(Available.Body.self == AnyView?.self)

        let buffer = renderToBuffer(Available(), context: testContext())
        #expect(buffer.lines.first?.stripped == "modern")
    }

    // MARK: - AnyView Erasure

    @Test("AnyView supports the erasing initializer")
    func anyViewErasingInitializer() {
        let erased = AnyView(erasing: Text("erased"))

        let buffer = renderToBuffer(erased, context: testContext())
        #expect(buffer.lines.first?.stripped == "erased")
    }
}
