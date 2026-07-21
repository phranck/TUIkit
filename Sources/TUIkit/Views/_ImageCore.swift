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

    /// Stores the source of the last committed load (`ImageSource?`).
    ///
    /// Written exclusively by the mounted loading task, never during
    /// traversal. A mismatch with the current source means the stored
    /// phase belongs to an outdated source.
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

        // Retrieve or create persistent phase state
        let phaseKey = StateStorage.StateKey(identity: identity, propertyIndex: StateIndex.phase)
        let phaseBox: StateBox<ImageLoadingPhase> = stateStorage.storage(for: phaseKey, default: .loading)
        let pendingEffects = context.environment.pendingFrameEffects
        if let pendingEffects {
            pendingEffects.markActive(identity)
        } else {
            stateStorage.markActive(identity)
        }

        // Track the source of the last committed load
        let sourceKey = StateStorage.StateKey(identity: identity, propertyIndex: StateIndex.lastSource)
        let lastSourceBox: StateBox<ImageSource?> = stateStorage.storage(for: sourceKey, default: nil)

        // The placeholder for a changed source is DERIVED instead of
        // written: state writes during traversal violate the render-phase
        // contract (they would emit RuntimeDiagnostics). The stored phase
        // only counts while it belongs to the current source; the mounted
        // task commits the new phase and source after the frame.
        let phase: ImageLoadingPhase = lastSourceBox.value == source
            ? phaseBox.value
            : .loading

        // The loading task is a lifetime effect bound to this image's
        // structural identity. The SOURCE is the restart ID: an unchanged
        // source keeps the mounted task, a changed source cancels it and
        // starts exactly one replacement. Recorded for the frame commit
        // inside RenderLoop passes; immediate on the live path.
        if context.phase == .render {
            mountLoadingTask(
                phaseBox: phaseBox,
                lastSourceBox: lastSourceBox,
                context: context
            )
        }

        // Render based on the derived phase
        switch phase {
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
    ///
    /// The task is the only writer of `phaseBox` and `lastSourceBox`; it
    /// commits them together once the load finishes, from outside the
    /// traversal window. Loader, cache, and limits are read from the
    /// render context's environment.
    private func mountLoadingTask(
        phaseBox: StateBox<ImageLoadingPhase>,
        lastSourceBox: StateBox<ImageSource?>,
        context: RenderContext
    ) {
        let lifecycle = context.environment.lifecycle!
        let imageLoader = context.environment.imageLoader
        let imageCache = context.environment.imageCache
        let urlTimeout = context.environment.imageURLTimeout
        let maxPixelCount = context.environment.imageMaxPixelCount
        let taskIdentity = context.identity.scoped("image.load")
        let src = source
        let mount = { [imageLoader, imageCache] in
            _ = lifecycle.updateTask(
                identity: taskIdentity,
                id: src,
                priority: .userInitiated
            ) {
                let loadedPhase: ImageLoadingPhase
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
                    loadedPhase = .success(rawImage)
                } catch let loadError as ImageLoadError {
                    loadedPhase = .failure(loadError.description)
                } catch {
                    loadedPhase = .failure(error.localizedDescription)
                }

                // A cancelled task lost its slot to a newer source;
                // committing its result would overwrite the replacement's.
                guard !Task.isCancelled else { return }

                // Phase first, then source: a render between the two writes
                // still derives the placeholder instead of pairing the fresh
                // phase with the outdated source. StateBox.didSet triggers
                // setNeedsRender() for each write.
                phaseBox.value = loadedPhase
                lastSourceBox.value = src
            }
        }
        if let pendingEffects = context.environment.pendingFrameEffects {
            pendingEffects.recordEffect(mount)
        } else {
            mount()
        }
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
