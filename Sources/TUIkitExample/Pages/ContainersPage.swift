//
//  ContainersPage.swift
//  TUIkitExample
//
//  Demonstrates container view capabilities.
//

import TUIkit

/// Container views demo page.
///
/// Shows various container views including:
/// - Card (bordered container with padding)
/// - Box (simple bordered container)
/// - Panel (container with title in border)
/// - ContainerView (with header and footer)
struct ContainersPage: View {
    var body: some View {
        VStack(spacing: 1) {
            HeaderView(title: "Container Views Demo")

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
                // ContainerView with Header and Footer (best for block appearance)
                DemoSection("ContainerView (Header + Footer)") {
                    ContainerView(title: "Settings", titleColor: .palette.accent) {
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

            DemoSection("Padding") {
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

            DemoSection("Appearance & BorderStyle") {
                Text("BorderStyle is determined by Appearance. Press 'a' to cycle.").foregroundColor(.palette.foregroundSecondary)
            }

            Spacer()
        }
    }
}
