//
//  Never+View.swift
//  TUIKit
//
//  Never conformance to View for primitive views with no body.
//

// MARK: - Never as View

/// `Never` conforms to View for views that have no body.
///
/// Primitive views like `Text` or containers like `TupleView` have no
/// body of their own - they are rendered directly. This extension allows
/// using `Never` as the body type.
extension Never: View {
    public var body: Never {
        fatalError("Never.body should never be called")
    }
}
