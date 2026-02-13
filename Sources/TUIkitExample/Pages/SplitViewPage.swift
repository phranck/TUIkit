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
    let body: String
    let date: String
    let isRead: Bool

    static func samples(for folder: String) -> [Self] {
        switch folder {
        case "inbox":
            return [
                Self(id: "1", from: "Alice", subject: "Meeting Tomorrow",
                     body: "Hi,\n\nJust wanted to confirm our meeting tomorrow at 2pm.\n\nBest,\nAlice",
                     date: "10:30", isRead: false),
                Self(id: "2", from: "Bob", subject: "Code Review",
                     body: "Hey,\n\nI've reviewed your PR and left some comments.\n\nLooks good overall!",
                     date: "09:15", isRead: false),
                Self(id: "3", from: "Carol", subject: "Project Update",
                     body: "Team,\n\nHere's the latest status on the project.\n\nWe're on track for launch.",
                     date: "Yesterday", isRead: true),
                Self(id: "4", from: "David", subject: "Quick Question",
                     body: "Hi,\n\nDo you have a moment to discuss the API design?\n\nThanks!",
                     date: "Yesterday", isRead: true),
                Self(id: "5", from: "Eve", subject: "New Feature Idea",
                     body: "Hello,\n\nI was thinking we could add dark mode support.\n\nThoughts?",
                     date: "Monday", isRead: true),
            ]
        case "starred":
            return [
                Self(id: "s1", from: "Frank", subject: "Important: Deadline",
                     body: "Reminder:\n\nThe deadline is next Friday.\n\nPlease submit your work.",
                     date: "Tuesday", isRead: true),
                Self(id: "s2", from: "Grace", subject: "Contract Review",
                     body: "Hi,\n\nPlease review the attached contract.\n\nLet me know if you have questions.",
                     date: "Last week", isRead: true),
            ]
        case "drafts":
            return [
                Self(id: "d1", from: "Me", subject: "Re: Meeting",
                     body: "Thanks for the invite.\n\nI'll be there at 2pm.\n\nSee you then!",
                     date: "Draft", isRead: true),
            ]
        default:
            return []
        }
    }
}

// MARK: - SplitView Page

/// NavigationSplitView demo page.
///
/// Shows a three-column mail client layout with interactive Lists:
/// - Sidebar: Folder list (Tab to focus)
/// - Content: Message list for selected folder
/// - Detail: Full message content
struct SplitViewPage: View {
    @State private var selectedFolder: String? = "inbox"
    @State private var selectedMessage: String? = "1"
    @State private var visibility: NavigationSplitViewVisibility = .all

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $visibility) {
                // Sidebar: Folder list
                List("Folders", selection: $selectedFolder) {
                    ForEach(Folder.samples) { folder in
                        HStack(spacing: 1) {
                            Text(folder.icon)
                            Text(folder.name)
                        }
                        .badge(folder.unreadCount)
                    }
                }
            } content: {
                // Content: Message list
                messageListContent
            } detail: {
                // Detail: Message content
                detailColumn
            }
            .navigationSplitViewStyle(.balanced)
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
    @ViewBuilder
    var messageListContent: some View {
        let messages = Message.samples(for: selectedFolder ?? "inbox")
        if messages.isEmpty {
            VStack {
                Spacer()
                Text("No messages in this folder").dim()
                Spacer()
            }
        } else {
            List(folderTitle, selection: $selectedMessage) {
                ForEach(messages) { message in
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
                        Text("-").dim()
                        Text(message.subject)
                    }
                }
            }
        }
    }

    var detailColumn: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let message = currentMessage {
                // Header
                Text(message.subject).bold().foregroundStyle(.palette.accent)
                Spacer(minLength: 1)
                HStack(spacing: 1) {
                    Text("From:").foregroundStyle(.palette.foregroundSecondary)
                    Text(message.from)
                }
                HStack(spacing: 1) {
                    Text("Date:").foregroundStyle(.palette.foregroundSecondary)
                    Text(message.date)
                }
                Spacer(minLength: 1)

                // Message body
                Text(message.body)
                Spacer()
            } else {
                Spacer()
                HStack {
                    Spacer()
                    Text("Select a message to view").dim()
                    Spacer()
                }
                Spacer()
            }
        }
        .padding(.horizontal, 1)
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
        case .all: return "All"
        case .doubleColumn: return "Double"
        case .detailOnly: return "Detail"
        default: return "Auto"
        }
    }
}
