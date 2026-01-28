//
//  main.swift
//  SwiftTUIExample
//
//  Entry point for the SwiftTUI example application.
//
//  This app demonstrates SwiftTUI capabilities through various demo pages.
//  Use the menu to navigate between demos.
//

import SwiftTUI

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
