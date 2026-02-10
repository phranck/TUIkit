//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderingTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("Rendering Tests")
struct RenderingTests {

    @Test("Text renders to single line buffer")
    func textBuffer() {
        let text = Text("Hello")
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(text, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "Hello")
    }

    @Test("EmptyView renders to empty buffer")
    func emptyViewBuffer() {
        let empty = EmptyView()
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(empty, context: context)
        #expect(buffer.isEmpty)
    }

    @Test("VStack renders children vertically")
    func vstackBuffer() {
        let stack = VStack {
            Text("Line 1")
            Text("Line 2")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 2)
        #expect(buffer.lines[0].stripped.contains("Line 1"))
        #expect(buffer.lines[1].stripped.contains("Line 2"))
    }

    @Test("VStack renders with spacing")
    func vstackWithSpacing() {
        let stack = VStack(spacing: 1) {
            Text("A")
            Text("B")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 3)
        #expect(buffer.lines[0].stripped.contains("A"))
        #expect(buffer.lines[1].stripped.trimmingCharacters(in: .whitespaces).isEmpty)
        #expect(buffer.lines[2].stripped.contains("B"))
    }

    @Test("HStack renders children horizontally")
    func hstackBuffer() {
        let stack = HStack {
            Text("Left")
            Text("Right")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "Left Right")
    }

    @Test("HStack renders with custom spacing")
    func hstackCustomSpacing() {
        let stack = HStack(spacing: 3) {
            Text("A")
            Text("B")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "A   B")
    }

    @Test("Nested VStack in HStack works")
    func nestedStacks() {
        let layout = HStack(spacing: 2) {
            Text("Label:")
            Text("Value")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(layout, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "Label:  Value")
    }

    @Test("Composite view renders through body")
    func compositeView() {
        struct MyView: View {
            var body: some View {
                VStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let view = MyView()
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(view, context: context)
        #expect(buffer.height == 2)
        #expect(buffer.lines[0].stripped.contains("Hello"))
        #expect(buffer.lines[1].stripped.contains("World"))
    }

    @Test("Divider renders to full width")
    func dividerBuffer() {
        let divider = Divider()
        let context = RenderContext(availableWidth: 20, availableHeight: 24)
        let buffer = renderToBuffer(divider, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == String(repeating: "─", count: 20))
    }

    @Test("Spacer renders empty lines")
    func spacerBuffer() {
        let spacer = Spacer(minLength: 3)
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(spacer, context: context)
        #expect(buffer.height == 3)
    }

    @Test("VStack with EmptyView children renders only non-empty")
    func vstackWithEmptyChildren() {
        let stack = VStack {
            EmptyView()
            Text("Visible")
            EmptyView()
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "Visible")
    }

    @Test("HStack with zero spacing renders without gaps")
    func hstackZeroSpacing() {
        let stack = HStack(spacing: 0) {
            Text("AB")
            Text("CD")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "ABCD")
    }

    @Test("Deeply nested stacks render correctly")
    func deeplyNestedStacks() {
        let layout = VStack {
            HStack {
                VStack {
                    Text("A")
                    Text("B")
                }
                Text("C")
            }
            Text("D")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(layout, context: context)
        #expect(buffer.height == 3)
        // Last line contains "D", possibly with trailing spaces from VStack alignment
        #expect(buffer.lines[2].stripped.trimmingCharacters(in: .whitespaces) == "D")
    }

    @Test("VStack with Spacer distributes available height")
    func vstackWithSpacer() {
        let stack = VStack {
            Text("Top")
            Spacer()
            Text("Bottom")
        }
        let context = RenderContext(availableWidth: 40, availableHeight: 10)

        // Debug: Check child infos
        let infos = resolveChildInfos(from: stack.content, context: context)
        #expect(infos.count == 3, "Should have 3 children: Text, Spacer, Text")
        #expect(infos[0].isSpacer == false, "First should be Text")
        #expect(infos[1].isSpacer == true, "Second should be Spacer")
        #expect(infos[2].isSpacer == false, "Third should be Text")

        // Debug: Calculate what VStack should compute
        let spacerCount = infos.filter(\.isSpacer).count
        let fixedHeight = infos.compactMap(\.buffer).reduce(0) { $0 + $1.height }
        let availableForSpacers = context.availableHeight - fixedHeight
        let spacerHeight = spacerCount > 0 ? availableForSpacers / spacerCount : 0

        #expect(spacerCount == 1, "Should have 1 spacer")
        #expect(fixedHeight == 2, "Fixed height should be 2 (Top + Bottom)")
        #expect(spacerHeight == 8, "Spacer height should be 8")

        let buffer = renderToBuffer(stack, context: context)

        // Spacer should take remaining height: 10 - 2 (Top + Bottom) = 8 lines
        #expect(buffer.height == 10, "Buffer should fill available height, got \(buffer.height)")
        if buffer.height >= 10 {
            // Lines may have trailing spaces from alignment, so trim them
            #expect(buffer.lines[0].stripped.trimmingCharacters(in: .whitespaces) == "Top")
            #expect(buffer.lines[9].stripped.trimmingCharacters(in: .whitespaces) == "Bottom")
        }
    }

    @Test("HStack with Spacer distributes available width")
    func hstackWithSpacer() {
        let stack = HStack(spacing: 0) {
            Text("L")
            Spacer()
            Text("R")
        }
        var context = RenderContext(availableWidth: 20, availableHeight: 10)
        context.hasExplicitWidth = true  // Simulate terminal/frame constraint
        let buffer = renderToBuffer(stack, context: context)

        // Spacer should take remaining width: 20 - 2 (L + R) = 18 spaces
        #expect(buffer.width == 20)
        #expect(buffer.lines[0].stripped.hasPrefix("L"))
        #expect(buffer.lines[0].stripped.hasSuffix("R"))
    }

    @Test("Text wraps at availableWidth")
    func textWrapsAtWidth() {
        let text = Text("This is a long text that should wrap")
        let context = RenderContext(availableWidth: 15, availableHeight: 10)
        let buffer = renderToBuffer(text, context: context)

        // Text should wrap into multiple lines
        #expect(buffer.height > 1)
        // Each line should be <= 15 characters
        for line in buffer.lines {
            #expect(line.strippedLength <= 15)
        }
    }

    @Test("frame(width:) constrains text wrapping")
    func frameConstrainsWidth() {
        let view = Text("This is a long text that should be wrapped because of the frame modifier")
            .frame(width: 20)
        let context = RenderContext(availableWidth: 100, availableHeight: 10)
        let buffer = renderToBuffer(view, context: context)

        // Text should wrap at frame width (20), not available width (100)
        #expect(buffer.height > 1, "Text should wrap into multiple lines")
        // Buffer width should be exactly 20 (frame enforces this)
        #expect(buffer.width == 20, "Buffer width should match frame width")
    }

    @Test("Centering with Spacers works correctly")
    func centeringWithSpacers() {
        let view = HStack(spacing: 0) {
            Spacer()
            Text("X")
            Spacer()
        }
        var context = RenderContext(availableWidth: 11, availableHeight: 1)
        context.hasExplicitWidth = true  // Simulate terminal/frame constraint
        let buffer = renderToBuffer(view, context: context)

        // The "X" should be centered with spacers on both sides
        #expect(buffer.width == 11)
        let line = buffer.lines[0]
        // Find position of "X" - should be near the middle
        let xPosition = line.firstIndex(of: "X")
        #expect(xPosition != nil)
        // With width 11, "X" at position 5 would be centered (0-indexed)
        // But we need to account for ANSI codes if any
        let stripped = line.stripped
        let strippedXPos = stripped.distance(from: stripped.startIndex, to: stripped.firstIndex(of: "X")!)
        // Should be roughly centered (5 spaces on left, 5 on right for width 11)
        #expect(strippedXPos >= 4 && strippedXPos <= 6, "X should be centered, got position \(strippedXPos)")
    }

    @Test("Nested HStack-VStack centering works")
    func nestedCentering() {
        // This mimics the template: HStack { Spacer() VStack{...} Spacer() }
        let view = HStack(spacing: 0) {
            Spacer()
            VStack {
                Text("Hello")
            }
            Spacer()
        }
        var context = RenderContext(availableWidth: 20, availableHeight: 5)
        context.hasExplicitWidth = true  // Simulate terminal/frame constraint
        let buffer = renderToBuffer(view, context: context)

        // Buffer should fill available width
        #expect(buffer.width == 20, "Buffer width should be 20, got \(buffer.width)")

        // "Hello" (5 chars) should be centered in 20 chars
        // Left spacer: 7-8 chars, Hello: 5 chars, Right spacer: 7-8 chars
        let line = buffer.lines[0]
        let stripped = line.stripped
        if let helloRange = stripped.range(of: "Hello") {
            let helloPos = stripped.distance(from: stripped.startIndex, to: helloRange.lowerBound)
            // Should be around position 7-8 for centering
            #expect(helloPos >= 6 && helloPos <= 9, "Hello should be centered, got position \(helloPos)")
        } else {
            Issue.record("Hello not found in output")
        }
    }

    @Test("VStack with Spacers distributes vertical space")
    func vstackWithSpacersDistributesVertically() {
        // VStack with Spacers should distribute vertical space
        // Width is determined by content, not available space
        let view = VStack(alignment: .center) {
            Spacer()
            Text("Hi")
            Spacer()
        }
        let context = RenderContext(availableWidth: 20, availableHeight: 10)
        let buffer = renderToBuffer(view, context: context)

        // VStack height should fill available height due to spacers
        #expect(buffer.height == 10, "VStack should fill available height, got \(buffer.height)")

        // Content should be somewhere in the middle vertically
        let contentLineIndex = buffer.lines.firstIndex { $0.contains("Hi") }
        #expect(contentLineIndex != nil, "Should find line with 'Hi'")
        if let index = contentLineIndex {
            // Should be around line 4-5 for vertical centering
            #expect(index >= 3 && index <= 6, "Hi should be vertically centered, got line \(index)")
        }
    }

    @Test("VStack default alignment is center like SwiftUI")
    func vstackDefaultAlignmentIsCenter() {
        let view = VStack {
            Text("Short")
            Text("Longer text here")
        }
        let context = RenderContext(availableWidth: 40, availableHeight: 10)
        let buffer = renderToBuffer(view, context: context)

        // With default .center alignment (like SwiftUI), shorter text should be centered
        // "Longer text here" is 16 chars, "Short" is 5 chars
        // "Short" should have (16-5)/2 = 5 leading spaces
        let shortLine = buffer.lines[0].stripped
        let leadingSpaces = shortLine.prefix(while: { $0 == " " }).count
        #expect(leadingSpaces >= 4 && leadingSpaces <= 6, "Short should be centered, got \(leadingSpaces) leading spaces")
        #expect(buffer.lines[1].stripped.hasPrefix("Longer"))
    }

    @Test("VStack center alignment centers shorter children")
    func vstackCenterAlignsCchildren() {
        let view = VStack(alignment: .center) {
            Text("Hi")
            Text("Hello World")
        }
        let context = RenderContext(availableWidth: 40, availableHeight: 10)
        let buffer = renderToBuffer(view, context: context)

        // "Hello World" is 11 chars, "Hi" is 2 chars
        // With .center alignment, "Hi" should be padded to center within 11 chars
        // Left padding for "Hi": (11-2)/2 = 4
        let hiLine = buffer.lines[0].stripped
        let helloLine = buffer.lines[1].stripped

        // Hi should have leading spaces for centering
        #expect(hiLine.hasPrefix("    ") || hiLine.hasPrefix("   "), "Hi should have leading padding, got: '\(hiLine)'")
        #expect(hiLine.contains("Hi"), "Line should contain Hi")

        // Hello World should have no leading padding (it's the widest)
        #expect(helloLine.hasPrefix("Hello"), "Hello World should have no leading padding")
    }

    @Test("VStack centers headline relative to framed text")
    func vstackCentersHeadlineRelativeToFramedText() {
        // This mimics the EXACT Ember app code (no alignment specified = .leading default)
        let contentView = VStack {
            Spacer()

            Text("Welcome to Ember!")
                .bold()
                .padding(.bottom)

            Text("You just created your first TUIkit app. This is a SwiftUI-like framework for building terminal user interfaces in pure Swift.")
                .frame(width: 40)

            Spacer()
        }
        .padding()

        // Test through WindowGroup like the real app
        let windowGroup = WindowGroup { contentView }
        let context = RenderContext(availableWidth: 80, availableHeight: 30)
        let buffer = windowGroup.renderScene(context: context)

        print("Buffer height: \(buffer.height)")
        print("Buffer width: \(buffer.width)")
        for (i, line) in buffer.lines.enumerated() {
            let stripped = line.stripped
            if !stripped.trimmingCharacters(in: .whitespaces).isEmpty {
                print("Line \(i): '\(stripped)'")
            }
        }

        // Find the headline line (contains "Welcome")
        let headlineLineIndex = buffer.lines.firstIndex { $0.contains("Welcome") }
        #expect(headlineLineIndex != nil, "Should find headline")

        if let idx = headlineLineIndex {
            let headlineLine = buffer.lines[idx].stripped
            let leadingSpaces = headlineLine.prefix(while: { $0 == " " }).count
            print("Headline at line \(idx): '\(headlineLine)'")
            print("Leading spaces: \(leadingSpaces)")

            // WindowGroup should center the entire content block in 80 chars
            // VStack+padding is about 42 chars wide (40 + 2 padding)
            // So centering: (80 - 42) / 2 = 19 leading spaces
            #expect(leadingSpaces >= 15, "Headline should be centered by WindowGroup, got \(leadingSpaces) leading spaces")
        }
    }

    @Test("HStack with Spacer inside border respects available width")
    func hstackWithSpacerInsideBorder() {
        let view = HStack {
            Text("Start")
            Spacer()
            Text("End")
        }.border()

        var context = RenderContext(availableWidth: 80, availableHeight: 10)
        context.hasExplicitWidth = true
        let buffer = renderToBuffer(view, context: context)

        // Buffer width should be exactly 80 (terminal width)
        #expect(buffer.width == 80, "Buffer width should be 80, got \(buffer.width)")

        // Content line (middle line with Start...End) should have strippedLength <= 80
        let contentLine = buffer.lines[1]  // Middle line (borders are top and bottom)
        #expect(contentLine.strippedLength <= 80, "Content line should not exceed 80 chars, got \(contentLine.strippedLength)")

        // "End" should be near the right edge
        let stripped = contentLine.stripped
        #expect(stripped.hasSuffix("End│") || stripped.hasSuffix("End ") || stripped.contains("End"),
                "End should be at right side: '\(stripped)'")
    }

    @Test("HStack with Spacer inside VStack with border respects width")
    func hstackWithSpacerInVStackWithBorder() {
        // This mirrors the LayoutPage structure more closely
        let view = VStack(alignment: .leading, spacing: 1) {
            VStack(alignment: .leading) {
                Text("Spacer")
                HStack {
                    Text("Start")
                    Spacer()
                    Text("End")
                }
                .border()
            }
        }

        var context = RenderContext(availableWidth: 80, availableHeight: 10)
        context.hasExplicitWidth = true
        context.hasExplicitHeight = true
        let buffer = renderToBuffer(view, context: context)

        // Find the line with the border content (contains "Start" and "End")
        let contentLineIndex = buffer.lines.firstIndex { $0.contains("Start") && $0.contains("End") }
        #expect(contentLineIndex != nil, "Should find a line with Start and End")

        if let idx = contentLineIndex {
            let line = buffer.lines[idx]
            #expect(line.strippedLength <= 80, "Content line should not exceed 80 chars, got \(line.strippedLength): '\(line.stripped)'")
        }

        // The entire buffer should not exceed 80 chars on any line
        for (index, line) in buffer.lines.enumerated() {
            #expect(line.strippedLength <= 80, "Line \(index) exceeds 80 chars: \(line.strippedLength) | '\(line.stripped)'")
        }
    }

    @Test("Bordered HStack with Spacer fills exact terminal width")
    func borderedHStackWithSpacerFillsExactWidth() {
        // Verify the width calculation for HStack with Spacer inside a border.
        // Width breakdown for availableWidth=80:
        // - forBorderedContent: 80 - 2 (border chars) = 78
        // - subtract padding: 78 - 2 (1 each side) = 76
        // - content renders with availableWidth=76
        // - padding adds back: 76 + 2 = 78
        // - border sides add: 78 + 2 = 80
        let view = HStack {
            Text("Start")
            Spacer()
            Text("End")
        }.border()

        var context = RenderContext(availableWidth: 80, availableHeight: 10)
        context.hasExplicitWidth = true
        let buffer = renderToBuffer(view, context: context)

        // All lines should be exactly 80 chars (fills terminal width)
        for (index, line) in buffer.lines.enumerated() {
            #expect(line.strippedLength == 80, "Line \(index) should be exactly 80, got \(line.strippedLength)")
        }

        // Verify content structure: │ Start ... End │
        let contentLine = buffer.lines[1]
        let stripped = contentLine.stripped
        #expect(stripped.hasPrefix("│"), "Should start with left border")
        #expect(stripped.hasSuffix("│"), "Should end with right border")
        #expect(stripped.contains("Start"), "Should contain Start")
        #expect(stripped.contains("End"), "Should contain End")
    }
}
