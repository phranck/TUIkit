//  TUIKit - Terminal UI Kit for Swift
//  SplitViewPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

// MARK: - Demo Data

/// A mail folder for the sidebar.
private struct Folder: Identifiable {
    let id: String
    let name: String
    let icon: String
    let unreadCount: Int

    static let samples: [Self] = [
        Self(id: "inbox", name: "Inbox", icon: "[>]", unreadCount: 12),
        Self(id: "starred", name: "Starred", icon: "[*]", unreadCount: 3),
        Self(id: "sent", name: "Sent", icon: "[^]", unreadCount: 0),
        Self(id: "drafts", name: "Drafts", icon: "[~]", unreadCount: 2),
        Self(id: "archive", name: "Archive", icon: "[=]", unreadCount: 0),
        Self(id: "trash", name: "Trash", icon: "[x]", unreadCount: 0),
    ]
}

/// A mail message for the content list.
private struct Message: Identifiable {
    let id: String
    let from: String
    let subject: String
    let preview: String
    let date: String
    let isRead: Bool

    static func samples(for folder: String) -> [Self] {
        switch folder {
        case "inbox":
            return [
                Self(id: "1", from: "Alice", subject: "Meeting Tomorrow",
                     preview: "Hi, just wanted to confirm...", date: "10:30", isRead: false),
                Self(id: "2", from: "Bob", subject: "Code Review",
                     preview: "I've reviewed your PR...", date: "09:15", isRead: false),
                Self(id: "3", from: "Carol", subject: "Project Update",
                     preview: "Here's the latest status...", date: "Yesterday", isRead: true),
                Self(id: "4", from: "David", subject: "Quick Question",
                     preview: "Do you have a moment...", date: "Yesterday", isRead: true),
                Self(id: "5", from: "Eve", subject: "New Feature Idea",
                     preview: "I was thinking we could...", date: "Monday", isRead: true),
            ]
        case "starred":
            return [
                Self(id: "s1", from: "Frank", subject: "Important: Deadline",
                     preview: "The deadline is next Friday...", date: "Tuesday", isRead: true),
                Self(id: "s2", from: "Grace", subject: "Contract Review",
                     preview: "Please review the attached...", date: "Last week", isRead: true),
            ]
        case "drafts":
            return [
                Self(id: "d1", from: "Me", subject: "Re: Meeting",
                     preview: "Thanks for the invite...", date: "Draft", isRead: true),
            ]
        default:
            return []
        }
    }
}

// MARK: - SplitView Page

/// NavigationSplitView demo page.
///
/// Shows a three-column mail client layout:
/// - Sidebar: Folder list
/// - Content: Message list for selected folder
/// - Detail: Message preview
struct SplitViewPage: View {
    @State private var selectedFolder: String? = "inbox"
    @State private var selectedMessage: String?
    @State private var visibility: NavigationSplitViewVisibility = .all

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $visibility) {
                // Sidebar: Folder list
                sidebarContent
            } content: {
                // Content: Message list
                contentColumn
            } detail: {
                // Detail: Message content
                detailColumn
            }
            .navigationSplitViewStyle(.balanced)

            // Visibility controls
            DemoSection("Visibility") {
                HStack(spacing: 2) {
                    Text("Current:").foregroundStyle(.palette.foregroundSecondary)
                    Text(visibilityLabel).bold().foregroundStyle(.palette.accent)
                    Spacer()
                    Text("[1] All  [2] Double  [3] Detail").dim()
                }
            }
            .onKeyPress { event in
                switch event.key {
                case .character("1"):
                    visibility = .all
                    return true
                case .character("2"):
                    visibility = .doubleColumn
                    return true
                case .character("3"):
                    visibility = .detailOnly
                    return true
                default:
                    return false
                }
            }
        }
        .appHeader {
            HStack {
                Text("NavigationSplitView Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}

// MARK: - Column Views

private extension SplitViewPage {
    var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Folders").bold().foregroundStyle(.palette.accent)
            Spacer(minLength: 1)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Folder.samples) { folder in
                    FolderRow(folder: folder, isSelected: selectedFolder == folder.id)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 1)
    }

    var contentColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(folderTitle).bold().foregroundStyle(.palette.accent)
            Spacer(minLength: 1)
            let messages = Message.samples(for: selectedFolder ?? "inbox")
            if messages.isEmpty {
                Text("No messages").dim()
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(messages) { message in
                        MessageRow(message: message, isSelected: selectedMessage == message.id)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 1)
    }

    var detailColumn: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let message = currentMessage {
                Text(message.subject).bold().foregroundStyle(.palette.accent)
                HStack(spacing: 1) {
                    Text("From:").foregroundStyle(.palette.foregroundSecondary)
                    Text(message.from)
                }
                HStack(spacing: 1) {
                    Text("Date:").foregroundStyle(.palette.foregroundSecondary)
                    Text(message.date)
                }
                Spacer(minLength: 1)
                Text(message.preview)
                Spacer()
            } else {
                Spacer()
                Text("Select a message").dim()
                Spacer()
            }
        }
        .padding(.horizontal, 1)
    }
}

// MARK: - Row Views

/// A folder row in the sidebar.
private struct FolderRow: View {
    let folder: Folder
    let isSelected: Bool

    private var hasUnread: Bool { folder.unreadCount > 0 }

    var body: some View {
        if isSelected {
            HStack(spacing: 1) {
                Text(folder.icon)
                Text(folder.name).bold()
                if hasUnread {
                    Spacer()
                    Text("(\(folder.unreadCount))").foregroundStyle(.palette.foregroundSecondary)
                }
            }
            .foregroundStyle(.palette.accent)
        } else {
            HStack(spacing: 1) {
                Text(folder.icon)
                Text(folder.name)
                if hasUnread {
                    Spacer()
                    Text("(\(folder.unreadCount))").foregroundStyle(.palette.foregroundSecondary)
                }
            }
        }
    }
}

/// A message row in the content column.
private struct MessageRow: View {
    let message: Message
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 1) {
                if message.isRead {
                    Text(" ")
                } else {
                    Text("*").foregroundStyle(.palette.accent)
                }
                if message.isRead {
                    Text(message.from)
                } else {
                    Text(message.from).bold()
                }
                Spacer()
                Text(message.date).dim()
            }
            if isSelected {
                Text(message.subject).foregroundStyle(.palette.accent)
            } else {
                Text(message.subject)
            }
        }
    }
}

// MARK: - Private Helpers

private extension SplitViewPage {
    var folderTitle: String {
        Folder.samples.first { $0.id == selectedFolder }?.name ?? "Messages"
    }

    var currentMessage: Message? {
        guard let messageId = selectedMessage else { return nil }
        return Message.samples(for: selectedFolder ?? "inbox").first { $0.id == messageId }
    }

    var visibilityLabel: String {
        switch visibility {
        case .all: return "All Columns"
        case .doubleColumn: return "Double Column"
        case .detailOnly: return "Detail Only"
        default: return "Automatic"
        }
    }
}
