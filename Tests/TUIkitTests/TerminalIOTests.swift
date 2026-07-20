//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TerminalIOTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

@testable import TUIkit

// MARK: - Terminal I/O Tests

@Suite("Terminal I/O Tests")
@MainActor
struct TerminalIOTests {
    @Test("Reading retries after an interrupted system call")
    func readRetriesAfterInterruption() {
        let script = TerminalIOScript(
            reads: [.failure(EINTR), .bytes([0x41])]
        )
        let terminal = Terminal(systemCalls: script.systemCalls)

        #expect(terminal.readBytes() == [0x41])
        #expect(script.readCallCount == 2)
    }

    @Test("Writing retries interruptions and partial writes")
    func writeRetriesInterruptionsAndPartialWrites() {
        let script = TerminalIOScript(
            writes: [.failure(EINTR), .count(2), .count(3)]
        )
        let terminal = Terminal(systemCalls: script.systemCalls)

        terminal.write("Hello")

        #expect(script.writtenBytes == Array("Hello".utf8))
        #expect(script.writeCallCount == 3)
    }

    @Test("A read failure is reported once")
    func readFailureIsReportedOnce() {
        let script = TerminalIOScript(reads: [.failure(EIO)])
        let terminal = Terminal(systemCalls: script.systemCalls)

        #expect(terminal.readBytes().isEmpty)
        #expect(
            terminal.takeIOFailure() == TerminalIOFailure(
                operation: .read,
                errorCode: EIO,
                remainingByteCount: 1
            )
        )
        #expect(terminal.takeIOFailure() == nil)
    }

    @Test("A write failure reports its remaining byte count")
    func writeFailureReportsRemainingBytes() {
        let script = TerminalIOScript(
            writes: [.count(2), .failure(EIO)]
        )
        let terminal = Terminal(systemCalls: script.systemCalls)

        terminal.write("Hello")

        #expect(script.writtenBytes == Array("He".utf8))
        #expect(
            terminal.takeIOFailure() == TerminalIOFailure(
                operation: .write,
                errorCode: EIO,
                remainingByteCount: 3
            )
        )
        #expect(terminal.takeIOFailure() == nil)
    }
}

// MARK: - Test Support

private final class TerminalIOScript: @unchecked Sendable {
    enum ReadStep: Sendable {
        case failure(Int32)
        case bytes([UInt8])
    }

    enum WriteStep: Sendable {
        case failure(Int32)
        case count(Int)
    }

    private let lock = NSLock()
    private var reads: [ReadStep]
    private var writes: [WriteStep]
    private var currentErrorCode: Int32 = 0
    private var storedReadCallCount = 0
    private var storedWriteCallCount = 0
    private var storedWrittenBytes: [UInt8] = []

    init(
        reads: [ReadStep] = [],
        writes: [WriteStep] = []
    ) {
        self.reads = reads
        self.writes = writes
    }

    var systemCalls: TerminalSystemCalls {
        TerminalSystemCalls(
            read: { [self] fileDescriptor, buffer, count in
                read(fileDescriptor: fileDescriptor, into: buffer, count: count)
            },
            write: { [self] fileDescriptor, buffer, count in
                write(fileDescriptor: fileDescriptor, from: buffer, count: count)
            },
            errorCode: { [self] in errorCode }
        )
    }

    var readCallCount: Int {
        withLock { storedReadCallCount }
    }

    var writeCallCount: Int {
        withLock { storedWriteCallCount }
    }

    var writtenBytes: [UInt8] {
        withLock { storedWrittenBytes }
    }
}

private extension TerminalIOScript {
    var errorCode: Int32 {
        withLock { currentErrorCode }
    }

    func read(
        fileDescriptor _: Int32,
        into buffer: UnsafeMutableRawPointer?,
        count: Int
    ) -> Int {
        withLock {
            storedReadCallCount += 1
            guard !reads.isEmpty else { return 0 }

            switch reads.removeFirst() {
            case let .failure(errorCode):
                currentErrorCode = errorCode
                return -1
            case let .bytes(bytes):
                currentErrorCode = 0
                guard let buffer else { return 0 }
                let byteCount = min(count, bytes.count)
                for index in 0..<byteCount {
                    buffer.storeBytes(of: bytes[index], toByteOffset: index, as: UInt8.self)
                }
                return byteCount
            }
        }
    }

    func write(
        fileDescriptor _: Int32,
        from buffer: UnsafeRawPointer?,
        count: Int
    ) -> Int {
        withLock {
            storedWriteCallCount += 1
            guard !writes.isEmpty else { return 0 }

            switch writes.removeFirst() {
            case let .failure(errorCode):
                currentErrorCode = errorCode
                return -1
            case let .count(requestedCount):
                currentErrorCode = 0
                guard let buffer else { return 0 }
                let byteCount = min(count, requestedCount)
                let bytes = buffer.assumingMemoryBound(to: UInt8.self)
                storedWrittenBytes.append(contentsOf: UnsafeBufferPointer(start: bytes, count: byteCount))
                return byteCount
            }
        }
    }

    func withLock<Result>(_ body: () -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
