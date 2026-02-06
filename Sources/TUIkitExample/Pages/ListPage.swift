//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ListPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Scrollable list demo page showing keyboard navigation and selection.
struct ListPage: View {
    @State var selectedItem: String?
    
    var body: some View {
        VStack(spacing: 1) {
            DemoSection("Basic List") {
                List(height: 8) {
                    Text("Item 1").foregroundColor(.palette.foreground)
                    Text("Item 2").foregroundColor(.palette.foreground)
                    Text("Item 3").foregroundColor(.palette.foreground)
                    Text("Item 4").foregroundColor(.palette.foreground)
                    Text("Item 5").foregroundColor(.palette.foreground)
                }
            }
            
            DemoSection("List with Selection") {
                List(selection: $selectedItem, height: 6) {
                    Text("Option A").foregroundColor(.palette.foreground).tag("a")
                    Text("Option B").foregroundColor(.palette.foreground).tag("b")
                    Text("Option C").foregroundColor(.palette.foreground).tag("c")
                    Text("Option D").foregroundColor(.palette.foreground).tag("d")
                }
            }
            
            DemoSection("Current Selection") {
                if let selected = selectedItem {
                    HStack(spacing: 1) {
                        Text("Selected:").foregroundColor(.palette.foregroundSecondary)
                        Text(selected).bold().foregroundColor(.palette.accent)
                    }
                } else {
                    Text("(none selected)").dim()
                }
            }
            
            DemoSection("Keyboard Navigation") {
                VStack {
                    Text("Use [↑/↓] to navigate items").dim()
                    Text("Use [Page Up/Down] to jump").dim()
                    Text("Use [Home/End] to jump to ends").dim()
                    Text("Use [Enter/Space] to select").dim()
                    Text("Use [Tab] to exit list").dim()
                }
            }
            
            Spacer()
        }
        .appHeader {
            HStack {
                Text("List Demo").bold().foregroundColor(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundColor(.palette.foregroundTertiary)
            }
        }
    }
}
