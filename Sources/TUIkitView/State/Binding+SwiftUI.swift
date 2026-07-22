//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Binding+SwiftUI.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Dynamic Member Lookup

extension Binding {
    /// Returns a binding to the resulting value of a given key path.
    ///
    /// Writing through the returned binding writes back into the original
    /// bound value, so nested properties stay two-way connected:
    ///
    /// ```swift
    /// @State private var profile = Profile(name: "…")
    /// TextField("Name", text: $profile.name)
    /// ```
    ///
    /// - Parameter keyPath: A key path to a specific value.
    /// - Returns: A new binding focused on the member at the key path.
    public subscript<Subject>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> Binding<Subject> {
        Binding<Subject>(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - Initializers

extension Binding {
    /// Creates a binding from the value of another binding.
    ///
    /// Matches SwiftUI's property-wrapper rewrapping initializer used by the
    /// compiler for `@Binding var value` declarations initialized from a
    /// projected value.
    ///
    /// - Parameter projectedValue: A binding to rewrap.
    public init(projectedValue: Binding<Value>) {
        self = projectedValue
    }

    /// Creates a binding by projecting the base value to an optional value.
    ///
    /// - Parameter base: A binding to a non-optional source of truth.
    public init<V>(_ base: Binding<V>) where Value == V? {
        self.init(
            get: { base.wrappedValue },
            set: { newValue in
                if let newValue {
                    base.wrappedValue = newValue
                }
            }
        )
    }

    /// Creates a binding by projecting the base optional value to its
    /// unwrapped value, or fails when the base value is `nil`.
    ///
    /// The returned binding reads the base at access time; if the base
    /// becomes `nil` later, reads keep returning the last known value while
    /// writes still target the base.
    ///
    /// - Parameter base: A binding to an optional source of truth.
    public init?(_ base: Binding<Value?>) {
        guard let initialValue = base.wrappedValue else { return nil }
        self.init(
            get: { base.wrappedValue ?? initialValue },
            set: { base.wrappedValue = $0 }
        )
    }

    /// Creates a binding by projecting the base value to a hashable value.
    ///
    /// - Parameter base: A binding to a hashable source of truth.
    public init<V>(_ base: Binding<V>) where Value == AnyHashable, V: Hashable {
        self.init(
            get: { AnyHashable(base.wrappedValue) },
            set: { newValue in
                if let typed = newValue.base as? V {
                    base.wrappedValue = typed
                }
            }
        )
    }
}

// MARK: - Identifiable Conformance

extension Binding: Identifiable where Value: Identifiable {
    /// The stable identity of the bound value.
    public var id: Value.ID {
        wrappedValue.id
    }
}

// MARK: - Collection Conformances

extension Binding: Sequence where Value: MutableCollection {
    public typealias Element = Binding<Value.Element>
    public typealias Iterator = IndexingIterator<Binding<Value>>
}

extension Binding: Collection where Value: MutableCollection {
    public typealias Index = Value.Index
    public typealias Indices = Value.Indices

    public var startIndex: Binding<Value>.Index {
        wrappedValue.startIndex
    }

    public var endIndex: Binding<Value>.Index {
        wrappedValue.endIndex
    }

    public var indices: Value.Indices {
        wrappedValue.indices
    }

    public func index(after position: Binding<Value>.Index) -> Binding<Value>.Index {
        wrappedValue.index(after: position)
    }

    public func formIndex(after position: inout Binding<Value>.Index) {
        wrappedValue.formIndex(after: &position)
    }

    /// Returns a writable binding to the element at the given position.
    public subscript(position: Binding<Value>.Index) -> Binding<Value>.Element {
        Binding<Value.Element>(
            get: { self.wrappedValue[position] },
            set: { self.wrappedValue[position] = $0 }
        )
    }
}

extension Binding: BidirectionalCollection where Value: BidirectionalCollection, Value: MutableCollection {
    public func index(before position: Binding<Value>.Index) -> Binding<Value>.Index {
        wrappedValue.index(before: position)
    }

    public func formIndex(before position: inout Binding<Value>.Index) {
        wrappedValue.formIndex(before: &position)
    }
}

extension Binding: RandomAccessCollection where Value: RandomAccessCollection, Value: MutableCollection {}

// MARK: - Sendable Boundary

extension Binding: @unchecked Sendable where Value: Sendable {}
