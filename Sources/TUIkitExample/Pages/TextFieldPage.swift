//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TextFieldPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// TextField demo page.
///
/// Shows interactive text field features including:
/// - Basic text input with cursor
/// - Cursor navigation (left/right/home/end)
/// - Text editing (insert, backspace, delete)
/// - onSubmit action
/// - Disabled state
/// - Live state display
struct TextFieldPage: View {
    @State var username: String = ""
    @State var email: String = ""
    @State var searchQuery: String = ""
    @State var disabledText: String = "Cannot edit"
    @State var submittedValue: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

            DemoSection("Basic Text Fields") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Username:").foregroundStyle(.palette.foregroundSecondary)
                        TextField("Username", text: $username)
                    }
                    HStack(spacing: 1) {
                        Text("Email:").foregroundStyle(.palette.foregroundSecondary)
                        TextField("Email", text: $email, prompt: Text("you@example.com"))
                    }
                }
            }

            DemoSection("With onSubmit") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Search:").foregroundStyle(.palette.foregroundSecondary)
                        TextField("Search", text: $searchQuery)
                            .onSubmit {
                                submittedValue = searchQuery
                            }
                    }
                    if !submittedValue.isEmpty {
                        HStack(spacing: 1) {
                            Text("Submitted:").foregroundStyle(.palette.foregroundSecondary)
                            Text(submittedValue).foregroundStyle(.palette.success)
                        }
                    }
                }
            }

            DemoSection("Disabled TextField") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Disabled:").foregroundStyle(.palette.foregroundSecondary)
                        TextField("Disabled", text: $disabledText).disabled()
                    }
                }
            }

            DemoSection("Current Values") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Username:").foregroundStyle(.palette.foregroundSecondary)
                        Text(username.isEmpty ? "(empty)" : "\"\(username)\"").foregroundStyle(.palette.accent)
                    }
                    HStack(spacing: 1) {
                        Text("Email:").foregroundStyle(.palette.foregroundSecondary)
                        Text(email.isEmpty ? "(empty)" : "\"\(email)\"").foregroundStyle(.palette.accent)
                    }
                    HStack(spacing: 1) {
                        Text("Search:").foregroundStyle(.palette.foregroundSecondary)
                        Text(searchQuery.isEmpty ? "(empty)" : "\"\(searchQuery)\"").foregroundStyle(.palette.accent)
                    }
                }
            }

            DemoSection("Keyboard Controls") {
                VStack(alignment: .leading) {
                    Text("Type any character to insert at cursor").dim()
                    Text("[←] [→] Move cursor left/right").dim()
                    Text("[Home] [End] Jump to start/end").dim()
                    Text("[Backspace] Delete before cursor").dim()
                    Text("[Delete] Delete at cursor").dim()
                    Text("[Enter] Submit (triggers onSubmit)").dim()
                    Text("[Tab] Move to next field").dim()
                }
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("TextField Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}
