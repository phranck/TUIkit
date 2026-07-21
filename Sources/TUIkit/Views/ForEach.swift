//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ForEach.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A view that generates views from a collection of data.
///
/// `ForEach` iterates over a collection and creates a view for each
/// element. The collection elements must be `Identifiable` or an
/// explicit ID key path must be provided.
///
/// Each generated child is associated with the element's explicit ID. The
/// identity remains stable when elements are inserted, removed, or reordered.
///
/// # Example with Identifiable
///
/// ```swift
/// struct Item: Identifiable {
///     let id: String
///     let name: String
/// }
///
/// let items = [Item(id: "1", name: "One"), Item(id: "2", name: "Two")]
///
/// VStack {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// }
/// ```
///
/// # Example with explicit ID key path
///
/// ```swift
/// let names = ["Anna", "Bob", "Clara"]
///
/// VStack {
///     ForEach(names, id: \.self) { name in
///         Text(name)
///     }
/// }
/// ```
public struct ForEach<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    /// The underlying data collection.
    let data: Data

    /// The key path to the unique ID of each element.
    let idKeyPath: KeyPath<Data.Element, ID>

    /// The closure that creates a view for each element.
    let content: (Data.Element) -> Content

    /// Creates a ForEach with an explicit ID key path.
    ///
    /// - Parameters:
    ///   - data: The collection to iterate over.
    ///   - id: The key path to the unique ID of each element.
    ///   - content: The closure that creates the view for each element.
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.idKeyPath = id
        self.content = content
    }

    public var body: some View {
        core
    }
}

// MARK: - Dynamic Children

extension ForEach: ChildInfoProvider, ChildViewProvider {
    public func childInfos(context: RenderContext) -> [ChildInfo] {
        core.childInfos(context: context)
    }

    public func childViews(context: RenderContext) -> [ChildView] {
        core.childViews(context: context)
    }
}

extension ForEach {
    func keyedSnapshot(context: RenderContext) -> KeyedCollectionSnapshot<Data.Element, ID> {
        let snapshot = KeyedCollectionSnapshot(data, id: idKeyPath)
        snapshot.reportDuplicates(container: "ForEach", context: context)
        return snapshot
    }
}

// MARK: - ForEach with Identifiable

extension ForEach where Data.Element: Identifiable, ID == Data.Element.ID {
    /// Creates a ForEach for Identifiable elements.
    ///
    /// - Parameters:
    ///   - data: The collection with Identifiable elements.
    ///   - content: The closure that creates the view for each element.
    public init(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.idKeyPath = \Data.Element.id
        self.content = content
    }
}

// MARK: - ForEach with Range

extension ForEach where Data == Range<Int>, ID == Int {
    /// Creates a ForEach over an integer range.
    ///
    /// - Parameters:
    ///   - data: The range, e.g., `0..<10`.
    ///   - content: The closure that creates the view for each index.
    public init(
        _ data: Range<Int>,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.data = data
        self.idKeyPath = \.self
        self.content = content
    }
}

// MARK: - Private Core

private extension ForEach {
    var core: _ForEachCore<Data, ID, Content> {
        _ForEachCore(data: data, idKeyPath: idKeyPath, content: content)
    }
}

private struct _ForEachCore<Data: RandomAccessCollection, ID: Hashable, Content: View>: View, Renderable,
    ChildInfoProvider, ChildViewProvider {
    let data: Data
    let idKeyPath: KeyPath<Data.Element, ID>
    let content: (Data.Element) -> Content

    var body: Never {
        fatalError("_ForEachCore renders its dynamic children directly")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        let snapshot = KeyedCollectionSnapshot(data, id: idKeyPath)
        snapshot.reportDuplicates(container: "ForEach", context: context)

        return snapshot.entries.map { entry in
            let view = content(entry.element)
            return makeChildInfo(
                for: view,
                context: context.withKeyedChildIdentity(
                    type: Content.self,
                    key: entry.identityKey
                )
            )
        }
    }

    func childViews(context: RenderContext) -> [ChildView] {
        let snapshot = KeyedCollectionSnapshot(data, id: idKeyPath)
        snapshot.reportDuplicates(container: "ForEach", context: context)

        return snapshot.entries.map { entry in
            ChildView(content(entry.element), key: entry.identityKey)
        }
    }
}
