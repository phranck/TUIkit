//  🖥️ TUIKit — Terminal UI Kit for Swift
//  BackgroundModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A modifier that fills the background of a view with a color.
///
/// - Important: This is framework infrastructure. Use `.background()` on any
///   ``View`` instead of instantiating this type directly.
public struct BackgroundModifier: ViewModifier {
    /// The background color.
    let color: Color

    public func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
        guard !buffer.isEmpty else { return buffer }

        let resolvedColor = color.resolve(with: context.environment.palette)
        return FrameBuffer(
            terminalSurface: buffer.terminalSurface.applyingBackground(
                resolvedColor.terminalBackgroundColor
            )
        )
    }
}

private extension Color {
    var terminalBackgroundColor: TerminalColor {
        switch value {
        case .standard(let color):
            .ansi(Int(color.backgroundCode))
        case .bright(let color):
            .ansi(Int(color.brightBackgroundCode))
        case .palette256(let index):
            .indexed(Int(index))
        case .rgb(let red, let green, let blue):
            .rgb(red: Int(red), green: Int(green), blue: Int(blue))
        case .semantic:
            preconditionFailure("Semantic color must be resolved before rendering")
        }
    }
}
