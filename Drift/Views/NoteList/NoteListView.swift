//
//  NoteListView.swift
//  Drift
//
//  List of notes with search and filtering
//

import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState: AppState
    
    @Query private var allNotes: [Note]
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    
    @State private var sortOrder: SortOrder = .updatedAt
    
    enum SortOrder: String, CaseIterable {
        case updatedAt = "Date Modified"
        case createdAt = "Date Created"
        case title = "Title"
    }
    
    var filteredNotes: [Note] {
        var notes = allNotes
        
        // Filter by sidebar selection
        switch appState.selectedSidebarItem {
        case .allNotes:
            notes = notes.filter { !$0.isTrashed && !$0.isArchived }
        case .favorites:
            notes = notes.filter { $0.isPinned && !$0.isTrashed }
        case .archive:
            notes = notes.filter { $0.isArchived && !$0.isTrashed }
        case .trash:
            notes = notes.filter { $0.isTrashed }
        case .folder(let folder):
            notes = notes.filter { $0.folder?.id == folder.id && !$0.isTrashed }
        case .tag(let tag):
            notes = notes.filter { $0.tags.contains { $0.id == tag.id } && !$0.isTrashed }
        }
        
        // Apply search filter
        if !appState.searchQuery.isEmpty {
            notes = notes.filter {
                $0.title.localizedCaseInsensitiveContains(appState.searchQuery) ||
                $0.content.localizedCaseInsensitiveContains(appState.searchQuery)
            }
        }
        
        // Sort notes (pinned first, then by sort order)
        return notes.sorted { note1, note2 in
            if note1.isPinned != note2.isPinned {
                return note1.isPinned
            }
            switch sortOrder {
            case .updatedAt:
                return note1.updatedAt > note2.updatedAt
            case .createdAt:
                return note1.createdAt > note2.createdAt
            case .title:
                return note1.title < note2.title
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $appState.searchQuery)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            Divider()
            
            // Notes list
            if filteredNotes.isEmpty {
                emptyStateView
            } else {
                List(filteredNotes, id: \.id, selection: $appState.selectedNote) { note in
                    NoteRowView(note: note)
                        .tag(note)
                        .contextMenu {
                            noteContextMenu(for: note)
                        }
                }
                .listStyle(.inset)
                .id(sortOrder)  // Force list refresh when sort order changes
            }
        }
        .background(Color(red: 0.1137, green: 0.1176, blue: 0.1569))
        .frame(minWidth: 250, idealWidth: 300)
        .toolbar {
            ToolbarItem {
                Button(action: createNewNote) {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Note")
                .keyboardShortcut("n", modifiers: .command)
            }
            
            ToolbarItem {
                Menu {
                    Picker("Sort By", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .help("Sort Notes")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text(emptyStateTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            if appState.selectedSidebarItem != .trash {
                Button("Create Note") {
                    createNewNote()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateIcon: String {
        switch appState.selectedSidebarItem {
        case .trash: return "trash"
        case .favorites: return "star"
        case .archive: return "archivebox"
        default: return "note.text"
        }
    }
    
    private var emptyStateTitle: String {
        if !appState.searchQuery.isEmpty {
            return "No Results"
        }
        switch appState.selectedSidebarItem {
        case .trash: return "Trash is Empty"
        case .favorites: return "No Favorites"
        case .archive: return "No Archived Notes"
        default: return "No Notes Yet"
        }
    }
    
    private var emptyStateMessage: String {
        if !appState.searchQuery.isEmpty {
            return "Try a different search term"
        }
        switch appState.selectedSidebarItem {
        case .trash: return "Deleted notes will appear here"
        case .favorites: return "Pin notes to add them to favorites"
        case .archive: return "Archived notes will appear here"
        default: return "Create your first note to get started"
        }
    }
    
    @ViewBuilder
    private func noteContextMenu(for note: Note) -> some View {
        Button(note.isPinned ? "Remove from Favorites" : "Add to Favorites", systemImage: note.isPinned ? "star.slash" : "star") {
            note.togglePin()
        }
        
        Divider()
        
        if !note.isTrashed {
            // Move to folder menu
            Menu("Move to Folder", systemImage: "folder") {
                Button("None") {
                    note.folder = nil
                    note.updatedAt = Date()
                }
                
                if !folders.isEmpty {
                    Divider()
                }
                
                ForEach(folders) { folder in
                    Button(folder.name, systemImage: folder.icon) {
                        note.folder = folder
                        note.updatedAt = Date()
                    }
                    .disabled(note.folder?.id == folder.id)
                }
            }
            
            Button("Archive", systemImage: "archivebox") {
                note.archive()
            }
            
            Divider()
            
            Button("Move to Trash", systemImage: "trash", role: .destructive) {
                note.moveToTrash()
                if appState.selectedNote == note {
                    appState.selectedNote = nil
                }
            }
        } else {
            Button("Restore", systemImage: "arrow.uturn.backward") {
                note.restore()
            }
            
            Button("Delete Permanently", systemImage: "trash.fill", role: .destructive) {
                modelContext.delete(note)
                if appState.selectedNote == note {
                    appState.selectedNote = nil
                }
            }
        }
    }
    
    private func createNewNote() {
        let folder: Folder? = {
            if case .folder(let f) = appState.selectedSidebarItem {
                return f
            }
            return nil
        }()
        
        let note = Note(title: "Untitled", content: "", folder: folder)
        modelContext.insert(note)
        appState.selectedNote = note
    }
}

// MARK: - Note Row
struct NoteRowView: View {
    @Bindable var note: Note
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // Favorite button - show on hover or if already favorited
                if isHovering || note.isPinned {
                    Button(action: { note.togglePin() }) {
                        Image(systemName: note.isPinned ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundStyle(note.isPinned ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(note.isPinned ? "Remove from Favorites" : "Add to Favorites")
                }
            }
            
            Text(note.preview.isEmpty ? "No content" : note.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search notes...", text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NoteListView(appState: AppState())
        .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}
