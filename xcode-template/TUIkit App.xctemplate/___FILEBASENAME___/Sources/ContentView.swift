//
//  ContentView.swift
//  ___VARIABLE_productName___
//

import TUIkit

/// The root view of the application.
struct ContentView: View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer()

            Text("Welcome to ___VARIABLE_productName___!")
                .bold()
                .foregroundColor(.accent)

            Spacer()

            Text("You just created your first TUIkit app. This is a SwiftUI-like framework for building terminal user interfaces in pure Swift.")
                .frame(width: 40)

            Spacer()
        }
        .padding()
    }
}
