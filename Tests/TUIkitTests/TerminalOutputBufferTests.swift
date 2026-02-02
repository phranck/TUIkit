//
//  TerminalOutputBufferTests.swift
//  TUIkit
//
//  Tests for Terminal's frame-buffered output system.
//

import Testing

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

import Foundation

@testable import TUIkit

// MARK: - Output Capture Helper

/// Captures all bytes written to `STDOUT_FILENO` during a closure.
///
/// Redirects stdout to a pipe, runs the closure, restores stdout,
/// and returns the captured bytes as a UTF-8 string.
private func captureStdout(_ body: () -> Void) -> String {
    var pipeFDs: [Int32] = [0, 0]
    pipe(&pipeFDs)

    let savedStdout = dup(STDOUT_FILENO)
    dup2(pipeFDs[1], STDOUT_FILENO)

    body()

    // Flush and close write end so read doesn't block
    close(pipeFDs[1])
    dup2(savedStdout, STDOUT_FILENO)
    close(savedStdout)

    // Read captured output
    var data = Data()
    var readBuffer = [UInt8](repeating: 0, count: 4096)
    while true {
        let bytesRead = read(pipeFDs[0], &readBuffer, readBuffer.count)
        if bytesRead <= 0 { break }
        data.append(contentsOf: readBuffer.prefix(bytesRead))
    }
    close(pipeFDs[0])

    return String(data: data, encoding: .utf8) ?? ""
}

// MARK: - Frame Buffer Tests

@Suite("Terminal Output Buffer Tests", .serialized)
struct TerminalOutputBufferTests {

    @Test("Buffered writes produce same output as unbuffered writes")
    func bufferedMatchesUnbuffered() {
        let unbuffered = captureStdout {
            let terminal = Terminal()
            terminal.write("Hello")
            terminal.write(" World")
        }

        let buffered = captureStdout {
            let terminal = Terminal()
            terminal.beginFrame()
            terminal.write("Hello")
            terminal.write(" World")
            terminal.endFrame()
        }

        #expect(unbuffered == "Hello World")
        #expect(buffered == "Hello World")
    }

    @Test("endFrame without beginFrame is a no-op")
    func endFrameWithoutBeginIsNoop() {
        let output = captureStdout {
            let terminal = Terminal()
            terminal.endFrame()
            terminal.write("After")
        }

        #expect(output == "After")
    }

    @Test("Double beginFrame is a no-op — buffer is not reset")
    func doubleBeginFrameIsNoop() {
        let output = captureStdout {
            let terminal = Terminal()
            terminal.beginFrame()
            terminal.write("First")
            terminal.beginFrame()  // should not reset buffer
            terminal.write("Second")
            terminal.endFrame()
        }

        #expect(output == "FirstSecond")
    }

    @Test("Multiple frames flush independently")
    func multipleFramesFlushIndependently() {
        var outputs: [String] = []

        outputs.append(captureStdout {
            let terminal = Terminal()
            terminal.beginFrame()
            terminal.write("Frame1")
            terminal.endFrame()
        })

        outputs.append(captureStdout {
            let terminal = Terminal()
            terminal.beginFrame()
            terminal.write("Frame2")
            terminal.endFrame()
        })

        #expect(outputs[0] == "Frame1")
        #expect(outputs[1] == "Frame2")
    }

    @Test("Empty frame produces no output")
    func emptyFrameProducesNoOutput() {
        let output = captureStdout {
            let terminal = Terminal()
            terminal.beginFrame()
            terminal.endFrame()
        }

        #expect(output.isEmpty)
    }

    @Test("Buffered frame handles ANSI escape sequences correctly")
    func bufferedFrameHandlesANSI() {
        let cursorMove = ANSIRenderer.moveCursor(toRow: 5, column: 1)
        var style = TextStyle()
        style.isBold = true
        let styled = ANSIRenderer.render("Bold", with: style)

        let output = captureStdout {
            let terminal = Terminal()
            terminal.beginFrame()
            terminal.write(cursorMove)
            terminal.write(styled)
            terminal.endFrame()
        }

        #expect(output.contains("\u{1B}[5;1H"))
        #expect(output.contains("\u{1B}[1m"))
        #expect(output.contains("Bold"))
    }
}
