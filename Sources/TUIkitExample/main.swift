//
//  main.swift
//  TUIkitExample
//
//  Entry point for the TUIkit example application.
//
//  This app demonstrates TUIkit capabilities through various demo pages.
//  Use the menu to navigate between demos.
//

import TUIkit

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
