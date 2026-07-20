//  🖥️ TUIKit — Terminal UI Kit for Swift
//  KeyedCollectionSnapshot.swift
//
//  License: MIT

/// A materialized keyed collection used by dynamic views and row containers.
///
/// Construction is linear. Every entry receives an occurrence-disambiguated
/// identity while public selection APIs continue to use the original ID.
struct KeyedCollectionSnapshot<Element, ID: Hashable> {
    struct Entry {
        let element: Element
        let id: ID
        let identityKey: KeyedCollectionIdentity<ID>
    }

    struct Duplicate {
        let id: ID
        let offsets: [Int]
    }

    let entries: [Entry]
    let duplicates: [Duplicate]

    init<Data: Collection>(
        _ data: Data,
        id idKeyPath: KeyPath<Element, ID>
    ) where Data.Element == Element {
        var entries: [Entry] = []
        entries.reserveCapacity(data.underestimatedCount)

        var offsetsByID: [ID: [Int]] = [:]
        var duplicateOrder: [ID] = []

        for (offset, element) in data.enumerated() {
            let id = element[keyPath: idKeyPath]
            let occurrence = offsetsByID[id, default: []].count
            offsetsByID[id, default: []].append(offset)
            if occurrence == 1 {
                duplicateOrder.append(id)
            }

            entries.append(
                Entry(
                    element: element,
                    id: id,
                    identityKey: KeyedCollectionIdentity(id: id, occurrence: occurrence)
                )
            )
        }

        self.entries = entries
        self.duplicates = duplicateOrder.compactMap { id in
            guard let offsets = offsetsByID[id] else { return nil }
            return Duplicate(id: id, offsets: offsets)
        }
    }
}

/// Internal identity key that keeps duplicate occurrences deterministic.
struct KeyedCollectionIdentity<ID: Hashable>: Hashable, CustomDebugStringConvertible {
    let id: ID
    let occurrence: Int

    var debugDescription: String {
        "\(String(reflecting: id))#\(occurrence)"
    }
}

extension KeyedCollectionSnapshot {
    func reportDuplicates(container: String, context: RenderContext) {
        guard let diagnostics = context.environment.runtimeDiagnostics else { return }

        for duplicate in duplicates {
            let offsets = duplicate.offsets.map(String.init).joined(separator: ", ")
            diagnostics.emit(
                RuntimeDiagnostic(
                    identity: context.identity,
                    message: "\(container) contains duplicate ID \(String(reflecting: duplicate.id)) at offsets \(offsets)"
                )
            )
        }
    }
}
