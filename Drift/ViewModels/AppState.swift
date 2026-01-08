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
    
    static func isNoteSelected(note: Note, selectedNote: Note?) -> Bool {
        guard let selectedNote = selectedNote else { return false }
        return note.id == selectedNote.id
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
