//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AppStorageFamilyTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

@MainActor
@Suite("AppStorage Initializer Families")
struct AppStorageFamilyTests {

    enum StringChoice: String {
        case first
        case second
    }

    enum IntChoice: Int {
        case one = 1
        case two = 2
    }

    struct CustomPayload: Codable, Equatable {
        var label: String
    }

    // MARK: - Typed Families

    @Test("Standard value families roundtrip through the injected store")
    func standardFamiliesRoundtrip() {
        let store = VolatileStorageBackend()

        let flag = AppStorage(wrappedValue: false, "flag", store: store)
        flag.wrappedValue = true
        #expect(flag.wrappedValue == true)

        let count = AppStorage(wrappedValue: 0, "count", store: store)
        count.wrappedValue = 7
        #expect(count.wrappedValue == 7)

        let ratio = AppStorage(wrappedValue: 0.0, "ratio", store: store)
        ratio.wrappedValue = 0.5
        #expect(ratio.wrappedValue == 0.5)

        let name = AppStorage(wrappedValue: "initial", "name", store: store)
        name.wrappedValue = "updated"
        #expect(name.wrappedValue == "updated")

        let link = AppStorage(wrappedValue: URL(fileURLWithPath: "/tmp"), "link", store: store)
        link.wrappedValue = URL(fileURLWithPath: "/var")
        #expect(link.wrappedValue == URL(fileURLWithPath: "/var"))

        let blob = AppStorage(wrappedValue: Data(), "blob", store: store)
        blob.wrappedValue = Data([1, 2, 3])
        #expect(blob.wrappedValue == Data([1, 2, 3]))

        let stamp = AppStorage(wrappedValue: Date(timeIntervalSince1970: 0), "stamp", store: store)
        stamp.wrappedValue = Date(timeIntervalSince1970: 100)
        #expect(stamp.wrappedValue == Date(timeIntervalSince1970: 100))
    }

    @Test("RawRepresentable families roundtrip without Codable conformance")
    func rawRepresentableFamiliesRoundtrip() {
        let store = VolatileStorageBackend()

        let choice = AppStorage(wrappedValue: StringChoice.first, "string-choice", store: store)
        choice.wrappedValue = .second
        #expect(choice.wrappedValue == .second)

        let number = AppStorage(wrappedValue: IntChoice.one, "int-choice", store: store)
        number.wrappedValue = .two
        #expect(number.wrappedValue == .two)
    }

    // MARK: - Optional Families

    @Test("Optional families start nil, store values, and clear on nil")
    func optionalFamiliesRoundtrip() {
        let store = VolatileStorageBackend()

        let name = AppStorage<String?>("optional-name", store: store)
        #expect(name.wrappedValue == nil)

        name.wrappedValue = "present"
        #expect(name.wrappedValue == "present")

        name.wrappedValue = nil
        #expect(name.wrappedValue == nil)

        let choice = AppStorage<StringChoice?>("optional-choice", store: store)
        #expect(choice.wrappedValue == nil)
        choice.wrappedValue = .first
        #expect(choice.wrappedValue == .first)
    }

    // MARK: - Codable Convenience

    @Test("Custom Codable payloads keep working as an additive convenience")
    func codableConvenienceStillWorks() {
        let store = VolatileStorageBackend()

        let payload = AppStorage(
            wrappedValue: CustomPayload(label: "default"),
            "payload",
            store: store
        )
        payload.wrappedValue = CustomPayload(label: "written")

        #expect(payload.wrappedValue == CustomPayload(label: "written"))
    }

    // MARK: - Store Sharing

    @Test("Two wrappers with the same key share the injected store")
    func wrappersShareInjectedStore() {
        let store = VolatileStorageBackend()

        let first = AppStorage(wrappedValue: 0, "shared", store: store)
        let second = AppStorage(wrappedValue: 0, "shared", store: store)

        first.wrappedValue = 99

        #expect(second.wrappedValue == 99)
    }
}
