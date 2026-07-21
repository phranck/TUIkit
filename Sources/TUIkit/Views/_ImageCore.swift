//  🖥️ TUIKit — Terminal UI Kit for Swift
//  _ImageCore.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - State Indices

/// Named property indices for `_ImageCore` state storage.
private enum StateIndex {
    /// Stores the loading phase (`ImageLoadingPhase`).
    static let phase = 0

    /// Stores the last loaded source for change detection (`ImageSource`).
    static let lastSource = 1
}

// MARK: - Image Core

/// Private rendering implementation for ``Image``.
///
/// Handles async image loading, caching, and placeholder display.
/// The raw `RGBAImage` is cached in state; ASCII conversion happens
/// on every render pass so that environment changes (character set,
/// color mode, dithering) take effect immediately.
struct _ImageCore: View, Renderable, Layoutable {
    /// The image source.
    let source: ImageSource

    var body: Never {
        fatalError("_ImageCore renders via Renderable")
    }

    // MARK: - Layoutable

    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        let proposedWidth = proposal.width ?? context.availableWidth
        let proposedHeight = proposal.height ?? context.availableHeight
        return .fixed(proposedWidth, proposedHeight)
    }

    // MARK: - Renderable

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let stateStorage = context.environment.stateStorage!
        let lifecycle = context.environment.lifecycle!
        let identity = context.identity

        let width = context.availableWidth
        let height = context.availableHeight

        guard width > 0, height > 0 else {
            return FrameBuffer()
        }

        // Read environment values
        let characterSet = context.environment.imageCharacterSet
        let colorMode = context.environment.imageColorMode
        let dithering = context.environment.imageDithering
        let contentMode = context.environment.imageContentMode
        let aspectRatioOverride = context.environment.imageAspectRatio
        let placeholderText = context.environment.imagePlaceholderText
        let showSpinner = context.environment.imagePlaceholderSpinner
        let maxPixelCount = context.environment.imageMaxPixelCount
        let urlTimeout = context.environment.imageURLTimeout
        let imageLoader = context.environment.imageLoader
        let imageCache = context.environment.imageCache

        // Retrieve or create persistent phase state
        let phaseKey = StateStorage.StateKey(identity: identity, propertyIndex: StateIndex.phase)
        let phaseBox: StateBox<ImageLoadingPhase> = stateStorage.storage(for: phaseKey, default: .loading)
        let pendingEffects = context.environment.pendingFrameEffects
        if let pendingEffects {
            pendingEffects.markActive(identity)
        } else {
            stateStorage.markActive(identity)
        }

        // Track the last loaded source to detect changes
        let sourceKey = StateStorage.StateKey(identity: identity, propertyIndex: StateIndex.lastSource)
        let lastSourceBox: StateBox<ImageSource?> = stateStorage.storage(for: sourceKey, default: nil)

        // Detect source change and show the placeholder for the new load.
        // Task cancellation and restart are handled by the updateTask
        // restart ID below (the source itself).
        resetLoadingPhaseIfNeeded(phaseBox: phaseBox, lastSourceBox: lastSourceBox)

        // The loading task is a lifetime effect bound to this image's
        // structural identity. The SOURCE is the restart ID: an unchanged
        // source keeps the mounted task, a changed source cancels it and
        // starts exactly one replacement. Recorded for the frame commit
        // inside RenderLoop passes; immediate on the live path.
        if context.phase == .render {
            mountLoadingTask(
                phaseBox: phaseBox,
                identity: identity,
                context: context,
                lifecycle: lifecycle,
                imageLoader: imageLoader,
                imageCache: imageCache,
                urlTimeout: urlTimeout,
                maxPixelCount: maxPixelCount
            )
        }

        // Render based on current phase
        switch phaseBox.value {
        case .loading:
            return renderPlaceholder(
                width: width,
                height: height,
                text: placeholderText,
                showSpinner: showSpinner,
                context: context
            )

        case .success(let rawImage):
            return renderImage(
                rawImage,
                width: width,
                height: height,
                characterSet: characterSet,
                colorMode: colorMode,
                dithering: dithering,
                contentMode: contentMode,
                aspectRatioOverride: aspectRatioOverride
            )

        case .failure(let message):
            return renderError(message, width: width, height: height, context: context)
        }
    }
}

// MARK: - Loading State

extension _ImageCore {

    /// Mounts the async loading task for the current source (lifetime
    /// effect: recorded for the frame commit inside RenderLoop passes,
    /// immediate on the live path).
    private func mountLoadingTask(
        phaseBox: StateBox<ImageLoadingPhase>,
        identity: ViewIdentity,
        context: RenderContext,
        lifecycle: LifecycleManager,
        imageLoader: any ImageLoader,
        imageCache: URLImageCache,
        urlTimeout: TimeInterval,
        maxPixelCount: Int?
    ) {
        let taskIdentity = identity.scoped("image.load")
        let src = source
        let mount = { [imageLoader, imageCache] in
            _ = lifecycle.updateTask(
                identity: taskIdentity,
                id: src,
                priority: .userInitiated
            ) {
                do {
                    let rawImage: RGBAImage
                    switch src {
                    case .file(let path):
                        rawImage = try imageLoader.loadImage(from: path, maxPixelCount: maxPixelCount)
                    case .url(let urlString):
                        rawImage = try imageLoader.loadImage(
                            from: urlString,
                            cache: imageCache,
                            timeout: urlTimeout,
                            maxPixelCount: maxPixelCount
                        )
                    }

                    // Store the raw image; conversion happens per render pass.
                    // StateBox.didSet triggers setNeedsRender() automatically.
                    // The runtime delivers that invalidation to its async event loop.
                    phaseBox.value = .success(rawImage)
                } catch let loadError as ImageLoadError {
                    phaseBox.value = .failure(loadError.description)
                } catch {
                    phaseBox.value = .failure(error.localizedDescription)
                }
            }
        }
        if let pendingEffects = context.environment.pendingFrameEffects {
            pendingEffects.recordEffect(mount)
        } else {
            mount()
        }
    }

    /// Resets the loading phase when the image source changes.
    ///
    /// Mutates state during rendering on purpose: the placeholder must show
    /// in the SAME frame the new source appears, not one frame later.
    private func resetLoadingPhaseIfNeeded(
        phaseBox: StateBox<ImageLoadingPhase>,
        lastSourceBox: StateBox<ImageSource?>
    ) {
        if let lastSource = lastSourceBox.value, lastSource != source {
            phaseBox.value = .loading
        }
        lastSourceBox.value = source
    }
}

// MARK: - Image Rendering

extension _ImageCore {

    /// Converts the raw image to ASCII art for the current frame dimensions and settings.
    private func renderImage(
        _ rawImage: RGBAImage,
        width: Int,
        height: Int,
        characterSet: ASCIICharacterSet,
        colorMode: ASCIIColorMode,
        dithering: DitheringMode,
        contentMode: ContentMode,
        aspectRatioOverride: Double?
    ) -> FrameBuffer {
        let targetSize = ASCIIConverter.targetSize(
            imageWidth: rawImage.width,
            imageHeight: rawImage.height,
            maxWidth: width,
            maxHeight: height,
            contentMode: contentMode,
            overrideAspectRatio: aspectRatioOverride
        )

        guard targetSize.width > 0, targetSize.height > 0 else {
            return FrameBuffer()
        }

        let converter = ASCIIConverter(
            characterSet: characterSet,
            colorMode: colorMode,
            dithering: dithering
        )
        let lines = converter.convert(rawImage, width: targetSize.width, height: targetSize.height)
        return FrameBuffer(lines: lines)
    }
}

// MARK: - Placeholder Rendering

extension _ImageCore {

    /// Renders a centered placeholder with optional spinner and text.
    private func renderPlaceholder(
        width: Int,
        height: Int,
        text: String?,
        showSpinner: Bool,
        context: RenderContext
    ) -> FrameBuffer {
        let palette = context.environment.palette

        // Build placeholder content lines
        var contentLines: [String] = []

        if showSpinner {
            let spinnerText = "⠋"
            let colored = ANSIRenderer.colorize(spinnerText, foreground: palette.accent)
            contentLines.append(colored)
        }

        if let text {
            let colored = ANSIRenderer.colorize(text, foreground: palette.foregroundSecondary)
            contentLines.append(colored)
        }

        if contentLines.isEmpty {
            contentLines.append(ANSIRenderer.colorize("Loading...", foreground: palette.foregroundSecondary))
        }

        return centerContent(contentLines, width: width, height: height)
    }

    /// Renders an error message centered in the frame.
    private func renderError(
        _ message: String,
        width: Int,
        height: Int,
        context: RenderContext
    ) -> FrameBuffer {
        let palette = context.environment.palette
        let errorText = ANSIRenderer.colorize("Error: \(message)", foreground: palette.error)
        return centerContent([errorText], width: width, height: height)
    }

    /// Centers content lines vertically and horizontally within the given dimensions.
    private func centerContent(_ contentLines: [String], width: Int, height: Int) -> FrameBuffer {
        let emptyLine = String(repeating: " ", count: width)
        var lines = [String](repeating: emptyLine, count: height)

        let startY = max(0, (height - contentLines.count) / 2)

        for (lineIndex, content) in contentLines.enumerated() {
            let rowIndex = startY + lineIndex
            guard rowIndex < height else { break }

            // Calculate visible width of content (excluding ANSI codes)
            let visibleWidth = content.filter { !$0.isASCII || ($0.asciiValue ?? 0) >= 32 }.count
            let padding = max(0, (width - visibleWidth) / 2)
            let padded = String(repeating: " ", count: padding) + content
            lines[rowIndex] = padded
        }

        return FrameBuffer(lines: lines, width: width)
    }
}
