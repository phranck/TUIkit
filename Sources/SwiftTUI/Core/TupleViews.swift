//
//  TupleViews.swift
//  SwiftTUI
//
//  Container types for multiple views in ViewBuilder.
//

// MARK: - TupleView2

/// A view that contains two child views.
public struct TupleView2<V0: View, V1: View>: View {
    public let value: (V0, V1)

    public init(_ v0: V0, _ v1: V1) {
        self.value = (v0, v1)
    }

    public var body: Never {
        fatalError("TupleView2 renders its children directly")
    }
}

// MARK: - TupleView3

/// A view that contains three child views.
public struct TupleView3<V0: View, V1: View, V2: View>: View {
    public let value: (V0, V1, V2)

    public init(_ v0: V0, _ v1: V1, _ v2: V2) {
        self.value = (v0, v1, v2)
    }

    public var body: Never {
        fatalError("TupleView3 renders its children directly")
    }
}

// MARK: - TupleView4

/// A view that contains four child views.
public struct TupleView4<V0: View, V1: View, V2: View, V3: View>: View {
    public let value: (V0, V1, V2, V3)

    public init(_ v0: V0, _ v1: V1, _ v2: V2, _ v3: V3) {
        self.value = (v0, v1, v2, v3)
    }

    public var body: Never {
        fatalError("TupleView4 renders its children directly")
    }
}

// MARK: - TupleView5

/// A view that contains five child views.
public struct TupleView5<V0: View, V1: View, V2: View, V3: View, V4: View>: View {
    public let value: (V0, V1, V2, V3, V4)

    public init(_ v0: V0, _ v1: V1, _ v2: V2, _ v3: V3, _ v4: V4) {
        self.value = (v0, v1, v2, v3, v4)
    }

    public var body: Never {
        fatalError("TupleView5 renders its children directly")
    }
}

// MARK: - TupleView6

/// A view that contains six child views.
public struct TupleView6<V0: View, V1: View, V2: View, V3: View, V4: View, V5: View>: View {
    public let value: (V0, V1, V2, V3, V4, V5)

    public init(_ v0: V0, _ v1: V1, _ v2: V2, _ v3: V3, _ v4: V4, _ v5: V5) {
        self.value = (v0, v1, v2, v3, v4, v5)
    }

    public var body: Never {
        fatalError("TupleView6 renders its children directly")
    }
}

// MARK: - TupleView7

/// A view that contains seven child views.
public struct TupleView7<V0: View, V1: View, V2: View, V3: View, V4: View, V5: View, V6: View>: View {
    public let value: (V0, V1, V2, V3, V4, V5, V6)

    public init(_ v0: V0, _ v1: V1, _ v2: V2, _ v3: V3, _ v4: V4, _ v5: V5, _ v6: V6) {
        self.value = (v0, v1, v2, v3, v4, v5, v6)
    }

    public var body: Never {
        fatalError("TupleView7 renders its children directly")
    }
}

// MARK: - TupleView8

/// A view that contains eight child views.
public struct TupleView8<V0: View, V1: View, V2: View, V3: View, V4: View, V5: View, V6: View, V7: View>: View {
    public let value: (V0, V1, V2, V3, V4, V5, V6, V7)

    public init(_ v0: V0, _ v1: V1, _ v2: V2, _ v3: V3, _ v4: V4, _ v5: V5, _ v6: V6, _ v7: V7) {
        self.value = (v0, v1, v2, v3, v4, v5, v6, v7)
    }

    public var body: Never {
        fatalError("TupleView8 renders its children directly")
    }
}

// MARK: - TupleView9

/// A view that contains nine child views.
public struct TupleView9<V0: View, V1: View, V2: View, V3: View, V4: View, V5: View, V6: View, V7: View, V8: View>: View {
    public let value: (V0, V1, V2, V3, V4, V5, V6, V7, V8)

    public init(_ v0: V0, _ v1: V1, _ v2: V2, _ v3: V3, _ v4: V4, _ v5: V5, _ v6: V6, _ v7: V7, _ v8: V8) {
        self.value = (v0, v1, v2, v3, v4, v5, v6, v7, v8)
    }

    public var body: Never {
        fatalError("TupleView9 renders its children directly")
    }
}

// MARK: - TupleView10

/// A view that contains ten child views.
public struct TupleView10<V0: View, V1: View, V2: View, V3: View, V4: View, V5: View, V6: View, V7: View, V8: View, V9: View>: View {
    public let value: (V0, V1, V2, V3, V4, V5, V6, V7, V8, V9)

    public init(_ v0: V0, _ v1: V1, _ v2: V2, _ v3: V3, _ v4: V4, _ v5: V5, _ v6: V6, _ v7: V7, _ v8: V8, _ v9: V9) {
        self.value = (v0, v1, v2, v3, v4, v5, v6, v7, v8, v9)
    }

    public var body: Never {
        fatalError("TupleView10 renders its children directly")
    }
}
