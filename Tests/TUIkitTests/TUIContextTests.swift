//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TUIContextTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Observation
import Testing
import TUIkitTestSupport

@testable import TUIkit

@MainActor
@Suite("TUIContext Tests")
struct TUIContextTests {

    @Test("Services are independent per context")
    func independentServices() {
        let contextA = TUIContext()
        let contextB = TUIContext()
        let slot = ViewIdentity(path: "a")
        // Each context has its own lifecycle manager
        contextA.lifecycle.recordAppear(identity: slot) {}
        #expect(contextA.lifecycle.hasAppeared(identity: slot) == true)
        #expect(contextB.lifecycle.hasAppeared(identity: slot) == false)
    }

    @Test("reset clears all services")
    func resetClears() {
        let context = TUIContext()
        let slot = ViewIdentity(path: "test")
        context.lifecycle.recordAppear(identity: slot) {}
        context.preferences.setValue("value", forKey: TestContextStringKey.self)
        context.keyEventDispatcher.addHandler { _ in true }

        context.reset()

        #expect(context.lifecycle.hasAppeared(identity: slot) == false)
        #expect(context.preferences.current[TestContextStringKey.self] == "default")
    }

    @Test("Preferences storage is functional")
    func preferencesWork() {
        let context = TUIContext()
        context.preferences.setValue("hello", forKey: TestContextStringKey.self)
        #expect(context.preferences.current[TestContextStringKey.self] == "hello")
    }

    @Test("KeyEventDispatcher is functional")
    func dispatcherWorks() {
        let context = TUIContext()
        nonisolated(unsafe) var handled = false
        context.keyEventDispatcher.addHandler { _ in
            handled = true
            return true
        }
        context.keyEventDispatcher.dispatch(KeyEvent(key: .enter))
        #expect(handled == true)
    }

    @Test("State mutation invalidates only its owning runtime")
    func stateMutationInvalidatesOnlyOwner() {
        let firstContext = TUIContext()
        let secondContext = TUIContext()
        let key = StateStorage.StateKey(
            identity: ViewIdentity(path: "owner"),
            propertyIndex: 0
        )
        let firstBox: StateBox<Int> = firstContext.stateStorage.storage(for: key, default: 0)
        let secondBox: StateBox<Int> = secondContext.stateStorage.storage(for: key, default: 0)

        firstContext.appState.didRender()
        secondContext.appState.didRender()
        firstBox.value = 1

        #expect(firstContext.appState.needsRender)
        #expect(secondContext.appState.needsRender == false)
        #expect(secondBox.value == 0)

        firstContext.applyPendingRenderInvalidations()

        #expect(firstContext.renderCache.stats.subtreeClears == 1)
        #expect(secondContext.renderCache.stats.subtreeClears == 0)
    }

    @Test("Observation invalidates only its rendering runtime")
    func observationInvalidatesOnlyRenderingRuntime() {
        let firstContext = TUIContext()
        let secondContext = TUIContext()
        let firstModel = RuntimeObservationModel()
        let secondModel = RuntimeObservationModel()

        _ = renderToBuffer(
            RuntimeObservationView(model: firstModel),
            context: RenderContext(
                availableWidth: 20,
                availableHeight: 1,
                tuiContext: firstContext
            )
        )
        _ = renderToBuffer(
            RuntimeObservationView(model: secondModel),
            context: RenderContext(
                availableWidth: 20,
                availableHeight: 1,
                tuiContext: secondContext
            )
        )

        firstContext.appState.didRender()
        secondContext.appState.didRender()
        firstModel.value = 1

        #expect(firstContext.appState.needsRender)
        #expect(secondContext.appState.needsRender == false)

        firstContext.applyPendingRenderInvalidations()

        #expect(firstContext.renderCache.stats.subtreeClears == 1)
        #expect(secondContext.renderCache.stats.clears == 0)
    }

    @Test("Observation registrations stay bounded and unmount with their identity")
    func observationRegistrationLifecycle() {
        let context = TUIContext()
        let model = RuntimeObservationModel()
        let renderContext = RenderContext(
            availableWidth: 20,
            availableHeight: 1,
            tuiContext: context,
            identity: ViewIdentity(path: "observed")
        )

        for _ in 0..<10 {
            context.beginRenderPass()
            _ = renderToBuffer(
                RuntimeObservationView(model: model),
                context: renderContext
            )
            context.endRenderPass()
        }

        #expect(context.observationRegistry.count == 1)

        context.beginRenderPass()
        context.endRenderPass()

        #expect(context.observationRegistry.isEmpty)

        context.appState.didRender()
        model.value = 1

        #expect(context.appState.needsRender == false)
    }

    @Test("Application services are isolated per runtime")
    func applicationServicesAreIsolatedPerRuntime() {
        let firstContext = TUIContext()
        let secondContext = TUIContext()

        #expect(firstContext.localizationService !== secondContext.localizationService)
        #expect(firstContext.notificationService !== secondContext.notificationService)
        #expect(firstContext.focusManager !== secondContext.focusManager)
        #expect(firstContext.paletteManager !== secondContext.paletteManager)
        #expect(firstContext.appearanceManager !== secondContext.appearanceManager)
        #expect(firstContext.statusBar !== secondContext.statusBar)
        #expect(firstContext.appHeader !== secondContext.appHeader)

        firstContext.localizationService.setLanguage(.german)
        firstContext.notificationService.post("first")
        firstContext.storageBackend.setValue("first", forKey: "runtime")
        let secondStoredValue: String? = secondContext.storageBackend.value(forKey: "runtime")

        #expect(firstContext.localizationService.currentLanguage == .german)
        #expect(secondContext.localizationService.currentLanguage == .english)
        #expect(firstContext.notificationService.activeEntries().map(\.message) == ["first"])
        #expect(secondContext.notificationService.activeEntries().isEmpty)
        #expect(secondStoredValue == nil)
    }

    @Test("Runtime services invalidate only their owning runtime")
    func runtimeServicesInvalidateOnlyTheirOwningRuntime() {
        let firstContext = TUIContext()
        let secondContext = TUIContext()

        func resetInvalidationState() {
            firstContext.applyPendingRenderInvalidations()
            secondContext.applyPendingRenderInvalidations()
            firstContext.appState.didRender()
            secondContext.appState.didRender()
        }

        func expectOnlyFirstContextNeedsRender() {
            #expect(firstContext.appState.needsRender)
            #expect(secondContext.appState.needsRender == false)
        }

        resetInvalidationState()
        firstContext.localizationService.setLanguage(.german)
        expectOnlyFirstContextNeedsRender()

        resetInvalidationState()
        firstContext.notificationService.post("first")
        expectOnlyFirstContextNeedsRender()

        resetInvalidationState()
        firstContext.paletteManager.cycleNext()
        expectOnlyFirstContextNeedsRender()

        resetInvalidationState()
        firstContext.appearanceManager.cycleNext()
        expectOnlyFirstContextNeedsRender()

        resetInvalidationState()
        firstContext.statusBar.setItems([])
        expectOnlyFirstContextNeedsRender()
    }

    @Test("Focus changes invalidate only the owning runtime")
    func focusChangesInvalidateOnlyOwningRuntime() {
        let firstContext = TUIContext()
        let secondContext = TUIContext()

        firstContext.appState.didRender()
        secondContext.appState.didRender()
        firstContext.focusManager.register(MockFocusable(id: "first"))

        #expect(firstContext.appState.needsRender)
        #expect(secondContext.appState.needsRender == false)
        #expect(firstContext.focusManager.currentFocusedID == "first")
        #expect(secondContext.focusManager.currentFocusedID == nil)
    }

    @Test("AppStorage binds to the owning runtime")
    func appStorageBindsToOwningRuntime() {
        let firstContext = TUIContext()
        let secondContext = TUIContext()
        let firstStorage = AppStorage(wrappedValue: "default", "runtime-key")
        let secondStorage = AppStorage(wrappedValue: "default", "runtime-key")
        let firstRenderContext = RenderContext(
            availableWidth: 20,
            availableHeight: 1,
            tuiContext: firstContext,
            identity: ViewIdentity(path: "first")
        )
        let secondRenderContext = RenderContext(
            availableWidth: 20,
            availableHeight: 1,
            tuiContext: secondContext,
            identity: ViewIdentity(path: "second")
        )

        firstContext.appState.didRender()
        secondContext.appState.didRender()
        StateRegistration.withHydration(context: firstRenderContext) {
            firstStorage.wrappedValue = "first"
        }

        let firstPersistedValue: String? = firstContext.storageBackend.value(forKey: "runtime-key")
        let secondPersistedValue: String? = secondContext.storageBackend.value(forKey: "runtime-key")
        #expect(firstPersistedValue == "first")
        #expect(secondPersistedValue == nil)
        #expect(firstContext.appState.needsRender)
        #expect(secondContext.appState.needsRender == false)

        firstContext.applyPendingRenderInvalidations()
        firstContext.appState.didRender()
        StateRegistration.withHydration(context: secondRenderContext) {
            secondStorage.wrappedValue = "second"
        }

        let firstValue = StateRegistration.withHydration(context: firstRenderContext) {
            firstStorage.wrappedValue
        }
        let secondValue = StateRegistration.withHydration(context: secondRenderContext) {
            secondStorage.wrappedValue
        }
        #expect(firstValue == "first")
        #expect(secondValue == "second")
        #expect(firstContext.appState.needsRender == false)
        #expect(secondContext.appState.needsRender)
    }

    @Test("Image requests and caches are isolated per runtime", .timeLimit(.minutes(1)))
    func imageRequestsAndCachesAreIsolatedPerRuntime() async {
        let firstLoader = RecordingRuntimeImageLoader()
        let secondLoader = RecordingRuntimeImageLoader()
        let firstCache = URLImageCache()
        let secondCache = URLImageCache()
        let firstContext = TUIContext(
            imageLoader: firstLoader,
            imageCache: firstCache
        )
        let secondContext = TUIContext(
            imageLoader: secondLoader,
            imageCache: secondCache
        )
        let url = "https://runtime.test/image.png"
        let image = Image(.url(url)).imagePlaceholderSpinner(false)

        _ = renderToBuffer(
            image,
            context: RenderContext(
                availableWidth: 4,
                availableHeight: 2,
                tuiContext: firstContext,
                identity: ViewIdentity(path: "image")
            )
        )
        await firstLoader.waitForRequest()
        #expect(firstLoader.requestedURLs == [url])
        #expect(secondLoader.requestedURLs.isEmpty)
        #expect(firstCache.get(url) != nil)
        #expect(secondCache.get(url) == nil)

        _ = renderToBuffer(
            image,
            context: RenderContext(
                availableWidth: 4,
                availableHeight: 2,
                tuiContext: secondContext,
                identity: ViewIdentity(path: "image")
            )
        )
        await secondLoader.waitForRequest()
        #expect(firstLoader.requestedURLs == [url])
        #expect(secondLoader.requestedURLs == [url])
        #expect(secondCache.get(url) != nil)

        firstContext.reset()
        secondContext.reset()
        #expect(firstCache.get(url) == nil)
        #expect(secondCache.get(url) == nil)
    }

    @Test("Render context receives the complete owning runtime")
    func renderContextReceivesCompleteOwningRuntime() {
        let storageBackend = VolatileStorageBackend()
        let tuiContext = TUIContext(
            storageBackend: storageBackend,
            clock: RuntimeClock { 42 }
        )
        let renderContext = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            tuiContext: tuiContext
        )

        #expect(renderContext.environment.stateStorage === tuiContext.stateStorage)
        #expect(renderContext.environment.observationRegistry === tuiContext.observationRegistry)
        #expect(renderContext.environment.lifecycle === tuiContext.lifecycle)
        #expect(renderContext.environment.keyEventDispatcher === tuiContext.keyEventDispatcher)
        #expect(renderContext.environment.renderCache === tuiContext.renderCache)
        #expect(renderContext.environment.renderInvalidationSink === tuiContext.appState)
        #expect(renderContext.environment.preferenceStorage === tuiContext.preferences)
        #expect(renderContext.environment.localizationService === tuiContext.localizationService)
        #expect(renderContext.environment.notificationService === tuiContext.notificationService)
        #expect(renderContext.environment.focusManager === tuiContext.focusManager)
        #expect(renderContext.environment.paletteManager === tuiContext.paletteManager)
        #expect(renderContext.environment.appearanceManager === tuiContext.appearanceManager)
        #expect(renderContext.environment.statusBar === tuiContext.statusBar)
        #expect(renderContext.environment.appHeader === tuiContext.appHeader)
        #expect(renderContext.environment.imageCache === tuiContext.imageCache)
        let environmentStorage = renderContext.environment.storageBackend as? VolatileStorageBackend
        #expect(environmentStorage === storageBackend)
        #expect(renderContext.environment.runtimeClock.now() == 42)
    }
}

/// Test preference key for TUIContext tests.
private struct TestContextStringKey: PreferenceKey {
    static let defaultValue: String = "default"
}

@Observable
private final class RuntimeObservationModel {
    var value = 0
}

private struct RuntimeObservationView: View {
    let model: RuntimeObservationModel

    var body: some View {
        Text("value:\(model.value)")
    }
}

private final class RecordingRuntimeImageLoader: ImageLoader, @unchecked Sendable {
    private let lock = NSLock()
    private let requestRecorded = AsyncSignal()
    private var urls: [String] = []
    private let image = RGBAImage(
        width: 1,
        height: 1,
        pixels: [RGBA(r: 255, g: 255, b: 255)]
    )

    var requestedURLs: [String] {
        lock.lock()
        defer { lock.unlock() }
        return urls
    }

    func waitForRequest() async {
        await requestRecorded.wait()
    }

    func loadImage(from path: String) throws -> RGBAImage {
        image
    }

    func loadImage(from data: Data) throws -> RGBAImage {
        image
    }

    func loadImage(
        from urlString: String,
        cache: URLImageCache,
        timeout: TimeInterval,
        maxPixelCount: Int?
    ) throws -> RGBAImage {
        cache.set(urlString, image: image)
        lock.lock()
        urls.append(urlString)
        lock.unlock()
        requestRecorded.signal()
        return image
    }
}
