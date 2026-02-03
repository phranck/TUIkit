//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ContainersPage.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

import TUIkit

/// Container views demo page.
///
/// Shows various container views including:
/// - Card (bordered container with padding)
/// - Box (simple bordered container)
/// - Panel (container with title in border)
/// - ContainerView (with header and footer)
/// - Collapsible detail section demonstrating `@State` toggle
struct ContainersPage: View {
    @State var showDetails: Bool = false

    var body: some View {
        VStack(spacing: 1) {

            HStack(spacing: 2) {
                // Card example
                VStack(alignment: .leading) {
                    Text("Card").bold().foregroundColor(.palette.accent)
                    Card(borderColor: .palette.border) {
                        Text("A Card view").foregroundColor(.palette.foreground)
                        Text("with padding").foregroundColor(.palette.foregroundSecondary)
                    }
                }

                // Box example
                VStack(alignment: .leading) {
                    Text("Box").bold().foregroundColor(.palette.accent)
                    Box(color: .palette.border) {
                        Text("Simple Box").foregroundColor(.palette.foreground)
                    }
                }

                // Panel example
                VStack(alignment: .leading) {
                    Text("Panel").bold().foregroundColor(.palette.accent)
                    Panel("Info", titleColor: .palette.accent) {
                        Text("Title in border").foregroundColor(.palette.foreground)
                    }
                }
            }

            HStack(spacing: 2) {
                // Panel with Header and Footer (best for block appearance)
                DemoSection("Panel (Header + Footer)") {
                    Panel("Settings", titleColor: .palette.accent) {
                        Text("Primary text (foreground)").foregroundColor(.palette.foreground)
                        Text("Secondary text (foregroundSecondary)").foregroundColor(.palette.foregroundSecondary)
                        Text("Tertiary text (foregroundTertiary)").foregroundColor(.palette.foregroundTertiary)
                    } footer: {
                        Text("Footer: Press Enter to confirm").foregroundColor(.palette.foreground)
                    }
                }

                // Alignment examples - uses different text lengths to show alignment
                DemoSection("Content Alignment") {
                    HStack(spacing: 1) {
                        Box {
                            VStack(alignment: .leading) {
                                Text("Leading align").foregroundColor(.palette.foreground)
                                Text("short").foregroundColor(.palette.foregroundSecondary)
                            }
                        }
                        Box {
                            VStack(alignment: .center) {
                                Text("Center align").foregroundColor(.palette.foreground)
                                Text("short").foregroundColor(.palette.foregroundSecondary)
                            }
                        }
                        Box {
                            VStack(alignment: .trailing) {
                                Text("Trailing align").foregroundColor(.palette.foreground)
                                Text("short").foregroundColor(.palette.foregroundSecondary)
                            }
                        }
                    }
                }
            }

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
                                Box {
                                    Text("h:1 v:0").foregroundColor(.palette.foreground)
                                        .padding(.horizontal, 1)
                                }
                                Box {
                                    Text("h:1 v:1").foregroundColor(.palette.foreground)
                                        .padding(EdgeInsets(horizontal: 1, vertical: 1))
                                }
                                Box {
                                    Text("h:1 v:2").foregroundColor(.palette.foreground)
                                        .padding(EdgeInsets(horizontal: 1, vertical: 2))
                                }
                            }
                        }
                    }
                }
            }

            DemoSection("Appearance & BorderStyle") {
                Text("BorderStyle is determined by Appearance. Press 'a' to cycle.").foregroundColor(.palette.foregroundSecondary)
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("Container Views Demo").bold().foregroundColor(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundColor(.palette.foregroundTertiary)
            }
        }
    }
}
