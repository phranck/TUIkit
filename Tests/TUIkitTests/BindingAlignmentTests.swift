//  🖥️ TUIKit — Terminal UI Kit for Swift
//  BindingAlignmentTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("Binding SwiftUI Alignment")
struct BindingAlignmentTests {

    /// A mutable box providing binding storage for tests.
    final class Storage<Value> {
        var value: Value

        init(_ value: Value) {
            self.value = value
        }

        var binding: Binding<Value> {
            Binding(get: { self.value }, set: { self.value = $0 })
        }
    }

    struct Profile: Equatable {
        var name: String
        var age: Int
    }

    // MARK: - Dynamic Member Lookup

    @Test("Dynamic member lookup produces writable child bindings")
    func dynamicMemberLookupWritesBack() {
        let storage = Storage(Profile(name: "initial", age: 30))
        let profile = storage.binding

        let name: Binding<String> = profile.name

        #expect(name.wrappedValue == "initial")

        name.wrappedValue = "changed"

        #expect(storage.value.name == "changed")
        #expect(storage.value.age == 30)
    }

    // MARK: - Initializers

    @Test("init(projectedValue:) rewraps a binding")
    func initProjectedValue() {
        let storage = Storage(7)
        let binding = Binding(projectedValue: storage.binding)

        binding.wrappedValue = 9

        #expect(storage.value == 9)
    }

    @Test("A non-optional binding promotes to an optional binding")
    func optionalPromotion() {
        let storage = Storage("value")
        let optional: Binding<String?> = Binding(storage.binding)

        #expect(optional.wrappedValue == "value")

        optional.wrappedValue = "updated"

        #expect(storage.value == "updated")
    }

    @Test("Unwrapping an optional binding fails for nil and writes back otherwise")
    func optionalUnwrapping() {
        let empty = Storage<String?>(nil)
        #expect(Binding<String>(empty.binding) == nil)

        let filled = Storage<String?>("present")
        let unwrapped = Binding<String>(filled.binding)
        #expect(unwrapped != nil)
        #expect(unwrapped?.wrappedValue == "present")

        unwrapped?.wrappedValue = "rewritten"
        #expect(filled.value == "rewritten")
    }

    // MARK: - Collection Conformance

    @Test("A collection binding yields writable element bindings")
    func collectionBindingElements() {
        let storage = Storage([1, 2, 3])
        let bindings = storage.binding

        #expect(bindings.count == 3)
        #expect(bindings[1].wrappedValue == 2)

        for element in bindings where element.wrappedValue == 3 {
            element.wrappedValue = 30
        }

        #expect(storage.value == [1, 2, 30])
    }

    // MARK: - Identifiable

    struct Item: Identifiable {
        let id: String
    }

    @Test("A binding to an Identifiable value shares its id")
    func identifiableBinding() {
        let storage = Storage(Item(id: "item-1"))

        #expect(storage.binding.id == "item-1")
    }
}
