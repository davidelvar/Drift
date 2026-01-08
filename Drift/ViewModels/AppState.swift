//
//  AppState.swift
//  Drift
//
//  Central app state management
//

import Foundation
import SwiftUI

@Observable
final class AppState {
    // Navigation state
    var selectedSidebarItem: SidebarItem = .allNotes
    var selectedNote: Note?
    var searchQuery: String = ""
    
    // UI state
    var isSearchFocused: Bool = false
    var isSidebarVisible: Bool = true
    var isInspectorVisible: Bool = false
    var isFocusMode: Bool = false
    
    // Editor state
    var isEditing: Bool = false
    var editorMode: EditorMode = .Edit
    
    init() {}
    
    func toggleFocusMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFocusMode.toggle()
        }
    }
}

// MARK: - Sidebar Items
enum SidebarItem: Hashable {
    case allNotes
    case favorites
    case archive
    case trash
    case folder(Folder)
    case tag(Tag)
    
    var title: String {
        switch self {
        case .allNotes: return "All Notes"
        case .favorites: return "Favorites"
        case .archive: return "Archive"
        case .trash: return "Trash"
        case .folder(let folder): return folder.name
        case .tag(let tag): return tag.name
        }
    }
    
    var icon: String {
        switch self {
        case .allNotes: return "note.text"
        case .favorites: return "star.fill"
        case .archive: return "archivebox"
        case .trash: return "trash"
        case .folder(let folder): return folder.icon
        case .tag: return "tag"
        }
    }
    
    var color: Color {
        switch self {
        case .allNotes: return .primary
        case .favorites: return .yellow
        case .archive: return .gray
        case .trash: return .red
        case .folder(let folder): return Color(folder.color)
        case .tag(let tag): return Color(tag.color)
        }
    }
}

// MARK: - Sidebar Row
struct SidebarRow: View {
    let item: SidebarItem
    var count: Int = 0
    
    var body: some View {
        HStack {
            Label {
                Text(item.title)
            } icon: {
                if case .allNotes = item {
                    AllNotesIcon()
                        .frame(width: 16, height: 16)
                } else if case .favorites = item {
                    FavoritesIcon()
                        .frame(width: 16, height: 16)
                } else if case .archive = item {
                    ArchiveIcon()
                        .frame(width: 16, height: 16)
                } else if case .trash = item {
                    TrashIcon()
                        .frame(width: 16, height: 16)
                } else if case .folder(let folder) = item {
                    if folder.name == "Ideas" {
                        Image("lightbulb")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    } else if folder.name == "Work" {
                        Image("work")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    } else if folder.name == "Personal" {
                        Image("personal")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    } else {
                        Image("folder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                } else if case .tag = item {
                    Image("tag")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: item.icon)
                        .foregroundStyle(item.color)
                }
            }
            
            Spacer()
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
        }
    }
}

// MARK: - All Notes Icon
struct AllNotesIcon: View {
    var body: some View {
        Image("16-notes")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Favorites Icon
struct FavoritesIcon: View {
    var body: some View {
        Image("star")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Archive Icon
struct ArchiveIcon: View {
    var body: some View {
        Image("archive")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Trash Icon
struct TrashIcon: View {
    var body: some View {
        Image("trash")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Color Extension
extension Color {
    init(_ name: String) {
        switch name {
        case "red": self = .red
        case "orange": self = .orange
        case "yellow": self = .yellow
        case "green": self = .green
        case "mint": self = .mint
        case "teal": self = .teal
        case "cyan": self = .cyan
        case "blue": self = .blue
        case "indigo": self = .indigo
        case "purple": self = .purple
        case "pink": self = .pink
        case "brown": self = .brown
        case "gray": self = .gray
        default: self = .primary
        }
    }
}
