//  🖥️ TUIKit — Terminal UI Kit for Swift
//  NotificationHostModifier.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

import Foundation

// MARK: - Notification Host Modifier

/// A modifier that renders all active notifications from the ``NotificationService``
/// as a stacked overlay.
///
/// Attach this modifier once at the root of your view tree. It reads the
/// active notification entries from the environment's ``NotificationService``,
/// renders each one as a bordered ``Box``, and stacks them vertically in the
/// top-right corner.
///
/// ## Example
///
/// ```swift
/// ContentView()
///     .notificationHost()
/// ```
///
/// The base content remains fully interactive — notifications do not dim
/// or block the background.
///
/// - SeeAlso: ``NotificationService``, ``View/notificationHost(width:)``
struct NotificationHostModifier<Content: View>: View {
    /// The base content to render.
    let content: Content

    /// The fixed width of each notification box in characters.
    let width: Int

    var body: Never {
        fatalError("NotificationHostModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension NotificationHostModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let baseBuffer = TUIkit.renderToBuffer(content, context: context)
        let service = context.environment.notificationService
        let activeEntries = service.activeEntries()

        guard !activeEntries.isEmpty else {
            return baseBuffer
        }

        // Start the animation timer if not already running.
        startAnimationTask(
            entries: activeEntries,
            lifecycle: context.tuiContext.lifecycle
        )

        let now = Date().timeIntervalSinceReferenceDate
        let palette = context.environment.palette
        let horizontalPadding = 1
        let innerWidth = max(1, width - BorderRenderer.borderWidthOverhead)
        let textWidth = max(1, innerWidth - horizontalPadding * 2)
        let pad = String(repeating: " ", count: horizontalPadding)

        // Render each notification as a Box and stack them vertically.
        var stackedBuffer = FrameBuffer()
        for entry in activeEntries {
            let elapsed = now - entry.postedAt
            let opacity = NotificationTiming.opacity(
                elapsed: elapsed,
                visibleDuration: entry.duration
            )

            let resolvedBorderColor = palette.border
            let fadedBorderColor = resolvedBorderColor.opacity(opacity)
            let fgColor = Color.palette.foreground.resolve(with: palette).opacity(opacity)

            // Build content lines with horizontal padding, padded to full inner width
            // so the Box spans the intended width.
            let wrappedLines = NotificationTiming.wordWrap(entry.message, maxWidth: textWidth)
            var contentLines: [String] = []
            for line in wrappedLines {
                let styledLine = pad + ANSIRenderer.colorize(line, foreground: fgColor)
                contentLines.append(styledLine.padToVisibleWidth(innerWidth))
            }

            // Render a Box around the pre-styled lines. Box handles
            // Border style adapts to the current appearance automatically.
            let boxView = Box(lines: contentLines, color: fadedBorderColor)
            var boxContext = context
            boxContext.availableWidth = width
            let entryBuffer = TUIkit.renderToBuffer(boxView, context: boxContext)

            stackedBuffer.appendVertically(entryBuffer)
        }

        guard !baseBuffer.isEmpty, !stackedBuffer.isEmpty else {
            return baseBuffer
        }

        // Expand the base buffer to fullscreen so the notification stack
        // is positioned relative to the terminal, not the content size.
        let screenWidth = context.availableWidth
        let screenHeight = context.availableHeight
        var fullscreenLines: [String] = []
        for row in 0..<screenHeight {
            if row < baseBuffer.lines.count {
                fullscreenLines.append(
                    baseBuffer.lines[row].padToVisibleWidth(screenWidth)
                )
            } else {
                fullscreenLines.append(String(repeating: " ", count: screenWidth))
            }
        }
        let fullscreenBuffer = FrameBuffer(lines: fullscreenLines)

        let offset = notificationOffset(
            stackSize: (stackedBuffer.width, stackedBuffer.height),
            screenSize: (screenWidth, screenHeight)
        )

        return fullscreenBuffer.composited(with: stackedBuffer, at: offset)
    }
}

// MARK: - Private Helpers

private extension NotificationHostModifier {
    /// Calculates the screen offset for the notification stack (always top-right).
    ///
    /// - Parameters:
    ///   - stackSize: The width and height of the stacked notification buffer.
    ///   - screenSize: The available terminal width and height.
    /// - Returns: The (x, y) position to place the stack.
    func notificationOffset(
        stackSize: (width: Int, height: Int),
        screenSize: (width: Int, height: Int)
    ) -> (x: Int, y: Int) {
        let xPosition = max(0, screenSize.width - stackSize.width - 1)
        return (xPosition, 1)
    }

    /// Starts a background task that triggers re-renders for fade animations
    /// and cleans up expired notifications.
    ///
    /// Uses a single shared token so only one animation task runs at a time.
    /// The task stops automatically when no notifications are active.
    func startAnimationTask(
        entries: [NotificationEntry],
        lifecycle: LifecycleManager
    ) {
        let token = "notification-host-animation"

        guard !lifecycle.hasAppeared(token: token) else { return }
        _ = lifecycle.recordAppear(token: token) {}

        // Calculate the latest expiration time across all entries.
        let totalOverhead = NotificationTiming.fadeInDuration + NotificationTiming.fadeOutDuration
        let latestExpiry = entries.map { $0.postedAt + $0.duration + totalOverhead }
            .max() ?? 0

        lifecycle.startTask(token: token, priority: .medium) { [lifecycle] in
            let triggerNanos: UInt64 = 40_000_000  // 40ms (~25 FPS)

            while !Task.isCancelled {
                let now = Date().timeIntervalSinceReferenceDate
                if now > latestExpiry {
                    break
                }
                try? await Task.sleep(nanoseconds: triggerNanos)
                guard !Task.isCancelled else { break }
                RenderNotifier.current.setNeedsRender()
            }

            // Final render to clear expired notifications.
            lifecycle.resetAppearance(token: token)
            RenderNotifier.current.setNeedsRender()
        }
    }
}
