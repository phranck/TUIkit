//  🖥️ TUIKit — Terminal UI Kit for Swift
//  DemoAppHeader.swift
//
//  Created by LAYERED.work
//  License: MIT

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

import Foundation
import TUIkit

/// Reusable app header for all Example App pages.
///
/// Shows the page title on the left, and version + system info on the right.
/// Optionally displays a subtitle below the title row.
///
/// # Example
///
/// ```swift
/// .appHeader { DemoAppHeader("Buttons Demo") }
/// .appHeader { DemoAppHeader("Main Menu", subtitle: "A SwiftUI-like framework") }
/// ```
struct DemoAppHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(title).bold().foregroundStyle(.palette.accent)
                    if let subtitle {
                        Text(subtitle)
                            .foregroundStyle(.palette.foregroundSecondary)
                            .italic()
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("TUIkit v\(tuiKitVersion)")
                    Text(systemInfo)
                }
                .foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}

// MARK: - System Info

extension DemoAppHeader {
    private var systemInfo: String {
        "\(osName) \(osVersion) · \(architecture)"
    }

    private var osName: String {
        #if os(macOS)
            return "macOS"
        #elseif os(Linux)
            return linuxDistroName
        #else
            return "Unknown"
        #endif
    }

    private var osVersion: String {
        #if os(macOS)
            let version = ProcessInfo.processInfo.operatingSystemVersion
            return "\(version.majorVersion).\(version.minorVersion)"
        #elseif os(Linux)
            return linuxDistroVersion
        #else
            return ""
        #endif
    }

    private var architecture: String {
        #if arch(arm64)
            return "arm64"
        #elseif arch(x86_64)
            return "x86_64"
        #else
            return "unknown"
        #endif
    }
}

// MARK: - Linux Distro Detection

#if os(Linux)
extension DemoAppHeader {
    /// Reads a value from /etc/os-release.
    private func osReleaseValue(for key: String) -> String? {
        guard let contents = try? String(contentsOfFile: "/etc/os-release", encoding: .utf8) else {
            return nil
        }
        for line in contents.split(separator: "\n") where line.hasPrefix("\(key)=") {
            let value = line.dropFirst(key.count + 1)
            return value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }

    private var linuxDistroName: String {
        osReleaseValue(for: "NAME") ?? "Linux"
    }

    private var linuxDistroVersion: String {
        osReleaseValue(for: "VERSION_ID") ?? kernelVersion
    }

    private var kernelVersion: String {
        var uts = utsname()
        uname(&uts)
        return withUnsafePointer(to: &uts.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(SYS_NMLN)) {
                String(cString: $0)
            }
        }
    }
}
#endif
