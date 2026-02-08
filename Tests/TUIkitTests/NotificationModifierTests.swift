//  🖥️ TUIKit — Terminal UI Kit for Swift
//  NotificationModifierTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

@MainActor
@Suite("Notification Tests", .serialized)
struct NotificationTests {

    /// Creates a test context with a fresh TUIContext.
    private func testContext(
        width: Int = 80,
        height: Int = 24,
        identity: ViewIdentity = ViewIdentity(path: "Root")
    ) -> RenderContext {
        RenderContext(
            availableWidth: width,
            availableHeight: height,
            tuiContext: TUIContext(),
            identity: identity
        )
    }

    // MARK: - Fade Timing

    @Test("Opacity is 0 at elapsed 0")
    func opacityAtStart() {
        let opacity = NotificationTiming.opacity(elapsed: 0.0, visibleDuration: 3.0)
        #expect(opacity == 0.0)
    }

    @Test("Opacity ramps to 1.0 at end of fade-in")
    func opacityAfterFadeIn() {
        let fadeIn = NotificationTiming.fadeInDuration
        let opacity = NotificationTiming.opacity(elapsed: fadeIn, visibleDuration: 3.0)
        #expect(opacity == 1.0)
    }

    @Test("Opacity is 1.0 during visible phase")
    func opacityDuringVisible() {
        let fadeIn = NotificationTiming.fadeInDuration
        let opacity = NotificationTiming.opacity(elapsed: fadeIn + 1.5, visibleDuration: 3.0)
        #expect(opacity == 1.0)
    }

    @Test("Opacity drops during fade-out phase")
    func opacityDuringFadeOut() {
        let fadeIn = NotificationTiming.fadeInDuration
        let visible = 3.0
        let halfFadeOut = NotificationTiming.fadeOutDuration / 2
        let opacity = NotificationTiming.opacity(elapsed: fadeIn + visible + halfFadeOut, visibleDuration: visible)
        #expect(opacity > 0.0)
        #expect(opacity < 1.0)
    }

    @Test("Opacity is 0 after full animation completes")
    func opacityAfterDismiss() {
        let total = NotificationTiming.fadeInDuration + 3.0 + NotificationTiming.fadeOutDuration + 0.1
        let opacity = NotificationTiming.opacity(elapsed: total, visibleDuration: 3.0)
        #expect(opacity == 0.0)
    }

    @Test("Fade-in is a linear ramp from 0 to 1")
    func fadeInIsLinear() {
        let fadeIn = NotificationTiming.fadeInDuration
        let quarter = NotificationTiming.opacity(elapsed: fadeIn * 0.25, visibleDuration: 3.0)
        let half = NotificationTiming.opacity(elapsed: fadeIn * 0.5, visibleDuration: 3.0)
        let threeQuarter = NotificationTiming.opacity(elapsed: fadeIn * 0.75, visibleDuration: 3.0)

        #expect(quarter > 0.0)
        #expect(half > quarter)
        #expect(threeQuarter > half)
        #expect(threeQuarter < 1.0)
        #expect(abs(half - 0.5) < 0.01)
    }

    // MARK: - Word Wrap

    @Test("Short text stays on one line")
    func wordWrapShortText() {
        let lines = NotificationTiming.wordWrap("Hello world", maxWidth: 40)
        #expect(lines == ["Hello world"])
    }

    @Test("Long text wraps at word boundaries")
    func wordWrapLongText() {
        let text = "This is a longer message that should wrap across multiple lines"
        let lines = NotificationTiming.wordWrap(text, maxWidth: 20)
        #expect(lines.count > 1)
        for line in lines {
            #expect(line.count <= 20)
        }
    }

    @Test("Single word longer than maxWidth gets its own line")
    func wordWrapLongWord() {
        let lines = NotificationTiming.wordWrap("Supercalifragilistic", maxWidth: 10)
        #expect(lines == ["Supercalifragilistic"])
    }

    @Test("Empty text returns single empty line")
    func wordWrapEmpty() {
        let lines = NotificationTiming.wordWrap("", maxWidth: 40)
        #expect(lines == [""])
    }

    // MARK: - NotificationService

    @Test("Post adds an entry to the service")
    func postAddsEntry() {
        let service = NotificationService()
        service.post("Hello")

        let entries = service.activeEntries()
        #expect(entries.count == 1)
        #expect(entries[0].message == "Hello")
    }

    @Test("Multiple posts stack entries in order")
    func multiplePostsStack() {
        let service = NotificationService()
        service.post("First")
        service.post("Second")
        service.post("Third")

        let entries = service.activeEntries()
        #expect(entries.count == 3)
        #expect(entries[0].message == "First")
        #expect(entries[1].message == "Second")
        #expect(entries[2].message == "Third")
    }

    @Test("Clear removes all entries")
    func clearRemovesAll() {
        let service = NotificationService()
        service.post("One")
        service.post("Two")
        service.clear()

        let entries = service.activeEntries()
        #expect(entries.isEmpty)
    }

    @Test("Expired entries are pruned by activeEntries")
    func expiredEntriesPruned() {
        let service = NotificationService()
        // Post with a very short duration so it expires almost immediately.
        service.post("Quick", duration: 0.0)

        // Wait slightly longer than fade-in + fade-out.
        Thread.sleep(forTimeInterval: NotificationTiming.fadeInDuration + NotificationTiming.fadeOutDuration + 0.05)

        let entries = service.activeEntries()
        #expect(entries.isEmpty)
    }

    // MARK: - NotificationHostModifier Rendering

    @Test("Host renders base content when no notifications are active")
    func hostRendersBaseWhenEmpty() {
        let context = testContext()
        let service = NotificationService()
        var env = context.environment
        env.notificationService = service

        let view = NotificationHostModifier(
            content: Text("Base"),
            width: 40
        )

        let buffer = renderToBuffer(view, context: context.withEnvironment(env))
        #expect(buffer.lines[0].stripped == "Base")
        #expect(buffer.height == 1)
    }

    @Test("Host renders notification overlay when entries exist")
    func hostRendersNotification() {
        let context = testContext()
        let service = NotificationService()
        service.post("Alert!")
        var env = context.environment
        env.notificationService = service

        let view = NotificationHostModifier(
            content: Text("Base"),
            width: 40
        )

        let buffer = renderToBuffer(view, context: context.withEnvironment(env))
        let joined = buffer.lines.joined()
        #expect(joined.contains("Alert!"))
    }

    @Test(".notificationHost() modifier compiles and renders correctly")
    func modifierExtension() {
        let context = testContext()
        let service = NotificationService()
        service.post("Done!")
        var env = context.environment
        env.notificationService = service

        let view = Text("Content").notificationHost()

        let buffer = renderToBuffer(view, context: context.withEnvironment(env))
        let joined = buffer.lines.joined()
        #expect(joined.contains("Done!"))
    }

    @Test("Multiple notifications stack vertically")
    func multipleNotificationsStack() {
        let context = testContext(width: 80, height: 24)
        let service = NotificationService()
        service.post("First")
        service.post("Second")
        var env = context.environment
        env.notificationService = service

        let view = Text("Base").notificationHost()

        let buffer = renderToBuffer(view, context: context.withEnvironment(env))
        let joined = buffer.lines.joined()
        #expect(joined.contains("First"))
        #expect(joined.contains("Second"))
        // Both notifications should be in the buffer, stacked.
        #expect(buffer.height > 3)
    }
}
