//
//  AppState.swift
//  Drift
//
//  Root app state container with feature-based sub-states
//

import Foundation
import SwiftUI

@Observable
final class AppState {
    // Feature-based state containers
    var editorState: EditorState
    var noteListState: NoteListState
    var sidebarState: SidebarState
    
    init(
        editorState: EditorState = EditorState(),
        noteListState: NoteListState = NoteListState(),
        sidebarState: SidebarState = SidebarState()
    ) {
        self.editorState = editorState
        self.noteListState = noteListState
        self.sidebarState = sidebarState
    }
    
    // MARK: - Convenience Properties (backward compatibility)
    var selectedSidebarItem: SidebarItem {
        get { sidebarState.selectedSidebarItem }
        set { sidebarState.selectedSidebarItem = newValue }
    }
    
    var selectedNote: Note? {
        get { noteListState.selectedNote }
        set { noteListState.selectedNote = newValue }
    }
    
    var searchQuery: String {
        get { noteListState.searchQuery }
        set { noteListState.searchQuery = newValue }
    }
    
    var editorMode: EditorMode {
        get { editorState.editorMode }
        set { editorState.editorMode = newValue }
    }
    
    var isFocusMode: Bool {
        get { editorState.isFocusMode }
        set { editorState.isFocusMode = newValue }
    }
    
    var isEditing: Bool {
        get { editorState.isEditing }
        set { editorState.isEditing = newValue }
    }
    
    var isSidebarVisible: Bool {
        get { sidebarState.isSidebarVisible }
        set { sidebarState.isSidebarVisible = newValue }
    }
    
    var isInspectorVisible: Bool {
        get { sidebarState.isInspectorVisible }
        set { sidebarState.isInspectorVisible = newValue }
    }
    
    // MARK: - Methods (forwarded to feature states)
    func toggleFocusMode() {
        editorState.toggleFocusMode()
    }
    
    func setEditorMode(_ mode: EditorMode) {
        editorState.setEditorMode(mode)
    }
    
    func selectSidebarItem(_ item: SidebarItem) {
        sidebarState.selectItem(item)
    }
    
    func selectNote(_ note: Note?) {
        noteListState.selectNote(note)
    }
    
    func setSearchQuery(_ query: String) {
        noteListState.setSearchQuery(query)
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
