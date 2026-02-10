//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ContainersPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Static row showing Card, Box, and Panel side by side.
///
/// Purely palette-driven, no state — wrapped in `.equatable()` for
/// subtree memoization during Spinner/Pulse animation frames.
struct ContainerTypesRow: View, Equatable {
    var body: some View {
        HStack(spacing: 2) {
            VStack(alignment: .leading) {
                Text("Card").bold().foregroundStyle(.palette.accent)
                Card(borderColor: .palette.border) {
                    Text("A Card view").foregroundStyle(.palette.foreground)
                    Text("with padding").foregroundStyle(.palette.foregroundSecondary)
                }
            }

            VStack(alignment: .leading) {
                Text(".border()").bold().foregroundStyle(.palette.accent)
                Text("Simple bordered content")
                    .foregroundStyle(.palette.foreground)
                    .border()
            }

            VStack(alignment: .leading) {
                Text("Panel").bold().foregroundStyle(.palette.accent)
                Panel("Info", titleColor: .palette.accent) {
                    Text("Title in border").foregroundStyle(.palette.foreground)
                }
            }
        }
    }
}

/// Static row showing a settings panel with footer and alignment examples.
///
/// Purely palette-driven, no state — wrapped in `.equatable()` for
/// subtree memoization during Spinner/Pulse animation frames.
struct SettingsAndAlignmentRow: View, Equatable {
    var body: some View {
        HStack(spacing: 2) {
            DemoSection("Panel (Header + Footer)") {
                Panel("Settings", titleColor: .palette.accent) {
                    Text("Primary text (foreground)").foregroundStyle(.palette.foreground)
                    Text("Secondary text (foregroundSecondary)").foregroundStyle(.palette.foregroundSecondary)
                    Text("Tertiary text (foregroundTertiary)").foregroundStyle(.palette.foregroundTertiary)
                } footer: {
                    Text("Footer: Press Enter to confirm").foregroundStyle(.palette.foreground)
                }
            }

            DemoSection("Content Alignment") {
                HStack(spacing: 1) {
                    VStack(alignment: .leading) {
                        Text("Leading align").foregroundStyle(.palette.foreground)
                        Text("short").foregroundStyle(.palette.foregroundSecondary)
                    }
                    .border()

                    VStack(alignment: .center) {
                        Text("Center align").foregroundStyle(.palette.foreground)
                        Text("short").foregroundStyle(.palette.foregroundSecondary)
                    }
                    .border()

                    VStack(alignment: .trailing) {
                        Text("Trailing align").foregroundStyle(.palette.foreground)
                        Text("short").foregroundStyle(.palette.foregroundSecondary)
                    }
                    .border()
                }
            }
        }
    }
}

/// Static row showing ProgressView examples.
///
/// Purely palette-driven, no state — wrapped in `.equatable()` for
/// subtree memoization during Spinner/Pulse animation frames.
/// Static row showing ProgressView examples with all 6 styles.
struct ProgressViewRow: View, Equatable {
    var body: some View {
        DemoSection("ProgressView") {
            VStack(alignment: .leading, spacing: 1) {
                ProgressView("Downloading files...", value: 0.73)

                ProgressView(value: 0.4) {
                    Text("Build progress").foregroundStyle(.palette.foreground)
                } currentValueLabel: {
                    Text("40%").foregroundStyle(.palette.foregroundSecondary)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Styles:").dim()
                    HStack(spacing: 1) {
                        Text("block    ").dim()
                        ProgressView(value: 0.6).trackStyle(.block)
                    }
                    HStack(spacing: 1) {
                        Text("blockFine").dim()
                        ProgressView(value: 0.6).trackStyle(.blockFine)
                    }
                    HStack(spacing: 1) {
                        Text("shade    ").dim()
                        ProgressView(value: 0.6).trackStyle(.shade)
                    }
                    HStack(spacing: 1) {
                        Text("bar      ").dim()
                        ProgressView(value: 0.6).trackStyle(.bar)
                    }
                    HStack(spacing: 1) {
                        Text("dot      ").dim()
                        ProgressView(value: 0.6).trackStyle(.dot)
                    }
                }
            }
        }
    }
}

/// Container views demo page.
///
/// Shows various container views including:
/// - Card (bordered container with padding)
/// - Box (simple bordered container)
/// - Panel (container with title in border)
/// - ProgressView (horizontal progress bar)
/// - Collapsible detail section demonstrating `@State` toggle
struct ContainersPage: View {
    @State var showDetails: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ContainerTypesRow().equatable()
            SettingsAndAlignmentRow().equatable()
            ProgressViewRow().equatable()

            DemoSection("Collapsible Detail (@State)") {
                VStack(alignment: .leading) {
                    HStack(spacing: 2) {
                        Button(showDetails ? "Hide Details" : "Show Details") {
                            showDetails.toggle()
                        }
                        Text(showDetails ? "expanded" : "collapsed")
                            .dim()
                    }
                    if showDetails {
                        Panel("Padding Examples", titleColor: .palette.accent) {
                            HStack(spacing: 1) {
                                Text("h:1 v:0").foregroundStyle(.palette.foreground)
                                    .padding(.horizontal, 1)
                                    .border()

                                Text("h:1 v:1").foregroundStyle(.palette.foreground)
                                    .padding(EdgeInsets(horizontal: 1, vertical: 1))
                                    .border()

                                Text("h:1 v:2").foregroundStyle(.palette.foreground)
                                    .padding(EdgeInsets(horizontal: 1, vertical: 2))
                                    .border()
                            }
                        }
                    }
                }
            }

            DemoSection("Appearance & BorderStyle") {
                Text("BorderStyle is determined by Appearance. Press 'a' to cycle.").foregroundStyle(.palette.foregroundSecondary)
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("Container Views Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}
