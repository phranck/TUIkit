//  🖥️ TUIKit — Terminal UI Kit for Swift
//  BindableTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation
import Testing

@testable import TUIkit

@MainActor
@Suite("Bindable")
struct BindableTests {

    @Observable
    final class Model {
        var text = "initial"
        var count = 0
    }

    @Test("Dynamic member lookup produces bindings that write into the model")
    func dynamicMemberWritesIntoModel() {
        let model = Model()
        let bindable = Bindable(model)

        let text: Binding<String> = bindable.text

        #expect(text.wrappedValue == "initial")

        text.wrappedValue = "changed"

        #expect(model.text == "changed")
    }

    @Test("The wrapper spellings share the same model instance")
    func wrapperSpellingsShareModel() {
        let model = Model()

        let byWrappedValue = Bindable(wrappedValue: model)
        let byValue = Bindable(model)
        let byProjection = Bindable(projectedValue: byValue)

        byWrappedValue.wrappedValue.count = 1

        #expect(byValue.wrappedValue.count == 1)
        #expect(byProjection.wrappedValue.count == 1)
        #expect(byValue.projectedValue.wrappedValue === model)
    }
}
