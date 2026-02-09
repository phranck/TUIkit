//  TUIKit - Terminal UI Kit for Swift
//  SecureFieldPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// SecureField demo page.
///
/// Shows secure text field features including:
/// - Password masking with bullet characters (●)
/// - Cursor navigation (left/right/home/end)
/// - Text editing (insert, backspace, delete)
/// - onSubmit action
/// - Disabled state
/// - Prompt text
struct SecureFieldPage: View {
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State var apiKey: String = ""
    @State var disabledPassword: String = "secret123"
    @State var submittedPassword: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

            DemoSection("Password Fields") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Password:").foregroundStyle(.palette.foregroundSecondary)
                        SecureField("Password", text: $password)
                    }
                    HStack(spacing: 1) {
                        Text("Confirm:").foregroundStyle(.palette.foregroundSecondary)
                        SecureField("Confirm", text: $confirmPassword, prompt: Text("Re-enter password"))
                    }
                }
            }

            DemoSection("With onSubmit") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("API Key:").foregroundStyle(.palette.foregroundSecondary)
                        SecureField("API Key", text: $apiKey)
                            .onSubmit {
                                submittedPassword = "Submitted \(apiKey.count) characters"
                            }
                    }
                    if !submittedPassword.isEmpty {
                        HStack(spacing: 1) {
                            Text("Status:").foregroundStyle(.palette.foregroundSecondary)
                            Text(submittedPassword).foregroundStyle(.palette.success)
                        }
                    }
                }
            }

            DemoSection("Disabled SecureField") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Disabled:").foregroundStyle(.palette.foregroundSecondary)
                        SecureField("Disabled", text: $disabledPassword).disabled()
                    }
                }
            }

            DemoSection("Password Validation") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Length:").foregroundStyle(.palette.foregroundSecondary)
                        Text("\(password.count) characters")
                            .foregroundStyle(password.count >= 8 ? .palette.success : .palette.warning)
                    }
                    HStack(spacing: 1) {
                        Text("Match:").foregroundStyle(.palette.foregroundSecondary)
                        if password.isEmpty && confirmPassword.isEmpty {
                            Text("(enter passwords)").dim()
                        } else if password == confirmPassword {
                            Text("Passwords match").foregroundStyle(.palette.success)
                        } else {
                            Text("Passwords differ").foregroundStyle(.palette.error)
                        }
                    }
                }
            }

            DemoSection("Keyboard Controls") {
                VStack(alignment: .leading) {
                    Text("Type any character to insert at cursor").dim()
                    Text("[Left] [Right] Move cursor left/right").dim()
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
                Text("SecureField Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}
