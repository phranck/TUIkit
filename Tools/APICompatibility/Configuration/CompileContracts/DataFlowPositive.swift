import Foundation
import Observation
import TUIkit

// Representative SwiftUI-style data-flow declarations that must compile
// unchanged under Swift 6.0: property wrappers, dynamic member bindings,
// typed AppStorage families, and custom dynamic properties.

@MainActor
struct DataFlowView: View {
    @State private var count = 0

    var body: some View {
        Text("\(count)")
    }
}

@Observable
private final class DataFlowModel {
    var name = ""
}

private struct DataFlowProfile {
    var title: String
}

@MainActor
private struct WrapperFamilies: View {
    @State private var profile = DataFlowProfile(title: "initial")
    @State private var optionalSelection: Int?
    @AppStorage("flag") private var flag = false
    @AppStorage("level") private var level = 0
    @AppStorage("nickname") private var nickname: String?
    @Bindable var model: DataFlowModel

    var body: some View {
        Text(profile.title)
    }

    @MainActor
    func derivedBindings() -> (Binding<String>, Binding<String>, Binding<Int?>) {
        ($profile.title, $model.name, $optionalSelection)
    }
}

private struct CustomDynamicProperty: DynamicProperty {
    @State private var backing = 0

    mutating func update() {}
}

@MainActor
private func constantCollectionBindings(_ values: Binding<[Int]>) -> [Binding<Int>] {
    values.map { $0 }
}
