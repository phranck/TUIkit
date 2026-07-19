//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StateStorageIdentityTests.swift
//
//  Created by LAYERED.work
//  License: MIT  branch switches invalidate state, and nested views get independent state.
//

import Testing
import TUIkitCore

@testable import TUIkitView

@MainActor
@Suite("State Storage Identity Tests", .serialized)
struct StateStorageIdentityTests {

    /// Creates a fresh StateStorage for test isolation.
    ///
    /// No invalidation sink is attached because these tests exercise storage
    /// identity without a running application runtime.
    private func testStorage() -> StateStorage {
        StateStorage()
    }

    // MARK: - Dynamic Property Binding

    @Test("State binds to storage at the committed identity")
    func dynamicPropertyBinding() {
        let storage = testStorage()
        let identity = ViewIdentity(path: "TestView")
        let context = HydrationContext(identity: identity, storage: storage)

        let first = SingleStateOwner(defaultValue: 42)
        StateRegistration.bindDynamicProperties(in: first, context: context)
        first.value = 99

        let reconstructed = SingleStateOwner(defaultValue: 42)
        StateRegistration.bindDynamicProperties(in: reconstructed, context: context)

        #expect(reconstructed.value == 99)
    }

    @Test("State uses local box when no active context is set")
    func localBoxWithoutContext() {
        let state = State(wrappedValue: "hello")
        #expect(state.wrappedValue == "hello")

        state.wrappedValue = "world"
        #expect(state.wrappedValue == "world")
    }

    @Test("Multiple @State properties get distinct indices")
    func multipleStateDistinctIndices() {
        let storage = testStorage()
        let identity = ViewIdentity(path: "MultiStateView")
        let context = HydrationContext(identity: identity, storage: storage)

        let first = MultipleStateOwner()
        StateRegistration.bindDynamicProperties(in: first, context: context)
        first.number = 20
        first.text = "world"

        let reconstructed = MultipleStateOwner()
        StateRegistration.bindDynamicProperties(in: reconstructed, context: context)

        #expect(reconstructed.number == 20)
        #expect(reconstructed.text == "world")
    }

    // MARK: - View Identity

    @Test("Child identity appends type and index")
    func childIdentityPath() {
        let root = ViewIdentity(path: "Root")
        let child = root.child(type: Int.self, index: 2)
        #expect(child.path == "Root/Int.2")
    }

    @Test("Branch identity uses hash separator")
    func branchIdentityPath() {
        let root = ViewIdentity(path: "Root")
        let branch = root.branch("true")
        #expect(branch.path == "Root#true")
    }

    @Test("Runtime scopes are stable and nested slots stay distinct")
    func scopedIdentityPath() {
        let root = ViewIdentity(path: "Root")

        let firstPass = root.scoped("lifecycle.appear")
        let secondPass = root.scoped("lifecycle.appear")
        let nested = firstPass.scoped("lifecycle.appear")

        #expect(firstPass == secondPass)
        #expect(nested != firstPass)
    }

    @Test("Explicit keys preserve child identity independently of sibling order")
    func keyedChildIdentity() {
        let root = ViewIdentity(path: "Root")

        let alphaBeforeReorder = root.keyedChild(type: String.self, key: "alpha")
        let betaBeforeReorder = root.keyedChild(type: String.self, key: "beta")
        let betaAfterReorder = root.keyedChild(type: String.self, key: "beta")
        let alphaAfterReorder = root.keyedChild(type: String.self, key: "alpha")

        #expect(alphaBeforeReorder == alphaAfterReorder)
        #expect(betaBeforeReorder == betaAfterReorder)
        #expect(alphaBeforeReorder != betaBeforeReorder)
        #expect(root.keyedChild(type: String.self, key: "a/b") != root.keyedChild(type: String.self, key: "a#b"))
    }

    @Test("isAncestor detects path descendants")
    func ancestorDetection() {
        let parent = ViewIdentity(path: "A/B")
        let child = ViewIdentity(path: "A/B/C")
        let sibling = ViewIdentity(path: "A/D")
        let branchChild = ViewIdentity(path: "A/B#true/C")

        #expect(parent.isAncestor(of: child) == true)
        #expect(parent.isAncestor(of: branchChild) == true)
        #expect(parent.isAncestor(of: sibling) == false)
        #expect(parent.isAncestor(of: parent) == false)
    }

    // MARK: - State Storage

    @Test("StateStorage returns same box for same key")
    func storageSameKey() {
        let storage = testStorage()
        let key = StateStorage.StateKey(
            identity: ViewIdentity(path: "V"),
            propertyIndex: 0
        )

        let box1: StateBox<Int> = storage.storage(for: key, default: 0)
        box1.value = 42
        let box2: StateBox<Int> = storage.storage(for: key, default: 0)

        #expect(box2.value == 42)
        #expect(box1 === box2)
    }

    @Test("StateStorage returns different boxes for different keys")
    func storageDifferentKeys() {
        let storage = testStorage()
        let key1 = StateStorage.StateKey(
            identity: ViewIdentity(path: "V"),
            propertyIndex: 0
        )
        let key2 = StateStorage.StateKey(
            identity: ViewIdentity(path: "V"),
            propertyIndex: 1
        )

        let box1: StateBox<Int> = storage.storage(for: key1, default: 10)
        let box2: StateBox<Int> = storage.storage(for: key2, default: 20)

        #expect(box1.value == 10)
        #expect(box2.value == 20)
        #expect(box1 !== box2)
    }

    // MARK: - Branch Invalidation

    @Test("invalidateDescendants removes state under a branch")
    func branchInvalidation() {
        let storage = testStorage()
        let branchIdentity = ViewIdentity(path: "Root#true")
        let childIdentity = ViewIdentity(path: "Root#true/Child")

        // Create state under the true branch
        let childKey = StateStorage.StateKey(identity: childIdentity, propertyIndex: 0)
        let box: StateBox<Int> = storage.storage(for: childKey, default: 5)
        box.value = 99

        // Invalidate the true branch
        storage.invalidateDescendants(of: branchIdentity)

        // State should be gone — new lookup returns default
        let newBox: StateBox<Int> = storage.storage(for: childKey, default: 5)
        #expect(newBox.value == 5)
        #expect(newBox !== box)
    }

    // MARK: - Render Pass GC

    @Test("endRenderPass removes state for views not marked active")
    func renderPassGarbageCollection() {
        let storage = testStorage()
        let activeIdentity = ViewIdentity(path: "Active")
        let staleIdentity = ViewIdentity(path: "Stale")

        // Create state for both
        let activeKey = StateStorage.StateKey(identity: activeIdentity, propertyIndex: 0)
        let staleKey = StateStorage.StateKey(identity: staleIdentity, propertyIndex: 0)
        let _: StateBox<Int> = storage.storage(for: activeKey, default: 1)
        let staleBox: StateBox<Int> = storage.storage(for: staleKey, default: 2)

        // Simulate render pass where only "Active" is seen
        storage.beginRenderPass()
        storage.markActive(activeIdentity)
        storage.endRenderPass()

        // Active state should survive
        let activeBox: StateBox<Int> = storage.storage(for: activeKey, default: 1)
        #expect(activeBox.value == 1)

        // Stale state should be gone — new lookup returns default
        let newStaleBox: StateBox<Int> = storage.storage(for: staleKey, default: 2)
        #expect(newStaleBox !== staleBox)
        #expect(newStaleBox.value == 2)
    }

    @Test("Keyed state follows reorder and removed keys are collected")
    func keyedStateReorderAndRemoval() {
        let storage = testStorage()
        let root = ViewIdentity(path: "Root")
        let firstIdentity = root.keyedChild(type: String.self, key: "first")
        let secondIdentity = root.keyedChild(type: String.self, key: "second")
        let firstKey = StateStorage.StateKey(identity: firstIdentity, propertyIndex: 0)
        let secondKey = StateStorage.StateKey(identity: secondIdentity, propertyIndex: 0)
        let firstBox: StateBox<Int> = storage.storage(for: firstKey, default: 1)
        let secondBox: StateBox<Int> = storage.storage(for: secondKey, default: 2)
        firstBox.value = 10
        secondBox.value = 20

        storage.beginRenderPass()
        storage.markActive(secondIdentity)
        storage.markActive(firstIdentity)
        storage.endRenderPass()

        let reorderedFirst: StateBox<Int> = storage.storage(for: firstKey, default: 1)
        let reorderedSecond: StateBox<Int> = storage.storage(for: secondKey, default: 2)
        #expect(reorderedFirst === firstBox)
        #expect(reorderedSecond === secondBox)
        #expect(reorderedFirst.value == 10)
        #expect(reorderedSecond.value == 20)

        storage.beginRenderPass()
        storage.markActive(firstIdentity)
        storage.endRenderPass()

        let recreatedSecond: StateBox<Int> = storage.storage(for: secondKey, default: 2)
        #expect(recreatedSecond !== secondBox)
        #expect(recreatedSecond.value == 2)
    }
}

// MARK: - Fixtures

private struct SingleStateOwner {
    @State var value: Int

    init(defaultValue: Int) {
        self._value = State(wrappedValue: defaultValue)
    }
}

private struct MultipleStateOwner {
    @State var number = 10
    @State var text = "hello"
}
