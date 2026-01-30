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
                    Text("Card").bold().foregroundColor(.theme.accent)
                    Card(borderColor: .theme.border) {
                        Text("A Card view").foregroundColor(.theme.foreground)
                        Text("with padding").foregroundColor(.theme.foregroundSecondary)
                    }
                }

                // Box example
                VStack(alignment: .leading) {
                    Text("Box").bold().foregroundColor(.theme.accent)
                    Box(color: .theme.border) {
                        Text("Simple Box").foregroundColor(.theme.foreground)
                    }
                }

                // Panel example
                VStack(alignment: .leading) {
                    Text("Panel").bold().foregroundColor(.theme.accent)
                    Panel("Info", titleColor: .theme.accent) {
                        Text("Title in border").foregroundColor(.theme.foreground)
                    }
                }
            }

            HStack(spacing: 2) {
                // ContainerView with Header and Footer (best for block appearance)
                DemoSection("ContainerView (Header + Footer)") {
                    ContainerView(title: "Settings", titleColor: .theme.accent) {
                        Text("Primary text (foreground)").foregroundColor(.theme.foreground)
                        Text("Secondary text (foregroundSecondary)").foregroundColor(.theme.foregroundSecondary)
                        Text("Tertiary text (foregroundTertiary)").foregroundColor(.theme.foregroundTertiary)
                    } footer: {
                        Text("Footer: Press Enter to confirm").foregroundColor(.theme.foreground)
                    }
                }

                // Alignment examples - uses different text lengths to show alignment
                DemoSection("Content Alignment") {
                    HStack(spacing: 1) {
                        Box {
                            VStack(alignment: .leading) {
                                Text("Leading align").foregroundColor(.theme.foreground)
                                Text("short").foregroundColor(.theme.foregroundSecondary)
                            }
                        }
                        Box {
                            VStack(alignment: .center) {
                                Text("Center align").foregroundColor(.theme.foreground)
                                Text("short").foregroundColor(.theme.foregroundSecondary)
                            }
                        }
                        Box {
                            VStack(alignment: .trailing) {
                                Text("Trailing align").foregroundColor(.theme.foreground)
                                Text("short").foregroundColor(.theme.foregroundSecondary)
                            }
                        }
                    }
                }
            }

            DemoSection("Padding") {
                HStack(spacing: 1) {
                    Box {
                        Text("h:1 v:0").foregroundColor(.theme.foreground)
                            .padding(.horizontal, 1)
                    }
                    Box {
                        Text("h:1 v:1").foregroundColor(.theme.foreground)
                            .padding(EdgeInsets(horizontal: 1, vertical: 1))
                    }
                    Box {
                        Text("h:1 v:2").foregroundColor(.theme.foreground)
                            .padding(EdgeInsets(horizontal: 1, vertical: 2))
                    }
                }
            }

            DemoSection("Appearance & BorderStyle") {
                Text("BorderStyle is determined by Appearance. Press 'a' to cycle.").foregroundColor(.theme.foregroundSecondary)
            }

            Spacer()
        }
    }
}
