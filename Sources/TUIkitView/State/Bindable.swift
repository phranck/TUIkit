//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Bindable.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation

// MARK: - Bindable

/// A property wrapper type that supports creating bindings to the mutable
/// properties of observable objects.
///
/// Matches SwiftUI's `Bindable`: wrap an `@Observable` model and use dynamic
/// member lookup to derive ``Binding`` values for its mutable properties:
///
/// ```swift
/// @Observable
/// final class Profile {
///     var name = ""
/// }
///
/// struct ProfileEditor: View {
///     @Bindable var profile: Profile
///
///     var body: some View {
///         TextField("Name", text: $profile.name)
///     }
/// }
/// ```
@propertyWrapper
@dynamicMemberLookup
public struct Bindable<Value> {
    /// The wrapped observable object.
    public var wrappedValue: Value

    /// The bindable wrapper itself, enabling `$model.property` bindings.
    public var projectedValue: Bindable<Value> {
        self
    }

    /// Designated storage initializer.
    ///
    /// Suppresses the synthesized internal memberwise initializer, which
    /// would violate the property-wrapper accessibility requirement; the
    /// public initializers below are constrained to observable objects.
    private init(storing wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: - Dynamic Member Lookup

extension Bindable where Value: AnyObject {
    /// Returns a binding to the value of a given key path.
    ///
    /// Writing through the returned binding mutates the observable object
    /// directly; Observation reports the change to the owning runtime.
    ///
    /// - Parameter keyPath: A reference-writable key path into the object.
    /// - Returns: A binding to the member at the key path.
    public subscript<Subject>(
        dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>
    ) -> Binding<Subject> {
        Binding(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - Initializers

extension Bindable where Value: AnyObject, Value: Observable {
    /// Creates a bindable object from an observable object.
    ///
    /// - Parameter wrappedValue: The observable object to wrap.
    public init(wrappedValue: Value) {
        self.init(storing: wrappedValue)
    }

    /// Creates a bindable object from an observable object.
    ///
    /// SwiftUI-compatible unlabeled spelling for direct construction.
    ///
    /// - Parameter wrappedValue: The observable object to wrap.
    public init(_ wrappedValue: Value) {
        self.init(storing: wrappedValue)
    }

    /// Creates a bindable from the value of another bindable.
    ///
    /// - Parameter projectedValue: A bindable to rewrap.
    public init(projectedValue: Bindable<Value>) {
        self = projectedValue
    }
}

// MARK: - Identifiable Conformance

extension Bindable: Identifiable where Value: Identifiable {
    /// The stable identity of the wrapped object.
    public var id: Value.ID {
        wrappedValue.id
    }
}

// MARK: - Dynamic Property Conformance

extension Bindable: DynamicProperty {}
