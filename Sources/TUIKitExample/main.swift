//
//  main.swift
//  TUIKitExample
//
//  Entry point for the TUIKit example application.
//
//  This app demonstrates TUIKit capabilities through various demo pages.
//  Use the menu to navigate between demos.
//

import TUIKit

// MARK: - Main App

/// The main example application.
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Run the app
ExampleApp.main()
