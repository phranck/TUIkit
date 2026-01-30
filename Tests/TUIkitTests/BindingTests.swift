//
//  BindingTests.swift
//  TUIkit
//
//  Tests for Binding property wrapper: get/set, projectedValue, constant.
//

import Testing

@testable import TUIkit

@Suite("Binding Tests")
struct BindingTests {

    @Test("Binding reads value via getter")
    func bindingGetter() {
        nonisolated(unsafe) var value = 42
        let binding = Binding(get: { value }, set: { value = $0 })
        #expect(binding.wrappedValue == 42)
    }

    @Test("Binding writes value via setter")
    func bindingSetter() {
        nonisolated(unsafe) var value = 0
        let binding = Binding(get: { value }, set: { value = $0 })
        binding.wrappedValue = 99
        #expect(value == 99)
    }

    @Test("Binding projectedValue returns self")
    func bindingProjectedValue() {
        nonisolated(unsafe) var value = "hello"
        let binding = Binding(get: { value }, set: { value = $0 })
        let projected = binding.projectedValue
        projected.wrappedValue = "world"
        #expect(value == "world")
    }

    @Test("Binding.constant always returns same value")
    func bindingConstant() {
        let binding = Binding.constant(42)
        #expect(binding.wrappedValue == 42)
        binding.wrappedValue = 99
        #expect(binding.wrappedValue == 42)
    }

    @Test("Binding reflects external changes")
    func bindingReflectsChanges() {
        nonisolated(unsafe) var value = 1
        let binding = Binding(get: { value }, set: { value = $0 })
        value = 5
        #expect(binding.wrappedValue == 5)
    }
}
