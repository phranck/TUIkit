import APICompatibilityKit
import Foundation

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

let result = CommandRunner().run(arguments: Array(CommandLine.arguments.dropFirst()))
if let output = result.standardOutput.data(using: .utf8) {
    FileHandle.standardOutput.write(output)
}
if let error = result.standardError.data(using: .utf8) {
    FileHandle.standardError.write(error)
}
exit(result.exitCode)
