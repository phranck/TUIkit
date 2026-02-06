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
                    Text("Item 1")
                    Text("Item 2")
                    Text("Item 3")
                    Text("Item 4")
                    Text("Item 5")
                }
            }
            
            DemoSection("List with Selection") {
                List(selection: $selectedItem, height: 6) {
                    Text("Option A").tag("a")
                    Text("Option B").tag("b")
                    Text("Option C").tag("c")
                    Text("Option D").tag("d")
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
