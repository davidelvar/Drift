//
//  ContentView.swift
//  Drift
//
//  A beautiful, extensible notes app for macOS
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView(appState: appState)
            } content: {
                NoteListView(appState: appState)
            } detail: {
                if let note = appState.selectedNote {
                    NoteEditorView(note: note, appState: appState)
                } else {
                    EmptyEditorView()
                }
            }
            .navigationTitle("")
            .opacity(appState.isFocusMode ? 0 : 1)
            
            // Focus Mode overlay
            if appState.isFocusMode, let note = appState.selectedNote {
                FocusModeView(note: note, appState: appState)
                    .transition(.opacity)
            }
        }
        .toolbar(appState.isFocusMode ? .hidden : .automatic)
        .onReceive(NotificationCenter.default.publisher(for: .createNewNote)) { _ in
            createNewNote()
        }
        .onReceive(NotificationCenter.default.publisher(for: .togglePin)) { _ in
            appState.selectedNote?.togglePin()
        }
        .onReceive(NotificationCenter.default.publisher(for: .moveToTrash)) { _ in
            if let note = appState.selectedNote {
                note.moveToTrash()
                appState.selectedNote = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .archiveNote)) { _ in
            if let note = appState.selectedNote {
                note.archive()
                appState.selectedNote = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            appState.isSearchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation {
                if columnVisibility == .all {
                    columnVisibility = .detailOnly
                } else {
                    columnVisibility = .all
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .setEditorMode)) { notification in
            if let mode = notification.object as? String {
                appState.editorMode = EditorMode(rawValue: mode.capitalized) ?? .Edit
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleFocusMode)) { _ in
            appState.toggleFocusMode()
        }
    }
    
    private func createNewNote() {
        let folder: Folder? = {
            if case .folder(let f) = appState.selectedSidebarItem {
                return f
            }
            return nil
        }()
        
        let note = Note(title: "", content: "", folder: folder)
        modelContext.insert(note)
        appState.selectedNote = note
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}
