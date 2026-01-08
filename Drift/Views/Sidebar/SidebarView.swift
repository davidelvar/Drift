//
//  SidebarView.swift
//  Drift
//
//  Navigation sidebar with folders and tags
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState: AppState
    
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Query private var allNotes: [Note]
    
    @State private var isAddingFolder = false
    @State private var newFolderName = ""
    
    // Computed counts
    private var allNotesCount: Int {
        allNotes.filter { !$0.isTrashed && !$0.isArchived }.count
    }
    
    private var favoritesCount: Int {
        allNotes.filter { $0.isPinned && !$0.isTrashed }.count
    }
    
    private var archiveCount: Int {
        allNotes.filter { $0.isArchived && !$0.isTrashed }.count
    }
    
    private var trashCount: Int {
        allNotes.filter { $0.isTrashed }.count
    }
    
    private func folderCount(_ folder: Folder) -> Int {
        allNotes.filter { $0.folder?.id == folder.id && !$0.isTrashed }.count
    }
    
    private func tagCount(_ tag: Tag) -> Int {
        allNotes.filter { $0.tags.contains { $0.id == tag.id } && !$0.isTrashed }.count
    }
    
    var body: some View {
        List(selection: $appState.selectedSidebarItem) {
            // Smart Folders Section
            Section("Library") {
                SidebarRow(item: .allNotes, count: allNotesCount)
                    .tag(SidebarItem.allNotes)
                
                SidebarRow(item: .favorites, count: favoritesCount)
                    .tag(SidebarItem.favorites)
                
                SidebarRow(item: .archive, count: archiveCount)
                    .tag(SidebarItem.archive)
                
                SidebarRow(item: .trash, count: trashCount)
                    .tag(SidebarItem.trash)
            }
            
            // User Folders Section
            Section("Folders") {
                ForEach(folders) { folder in
                    SidebarRow(item: .folder(folder), count: folderCount(folder))
                        .tag(SidebarItem.folder(folder))
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deleteFolder(folder)
                            }
                        }
                }
                
                if isAddingFolder {
                    TextField("Folder name", text: $newFolderName)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            createFolder()
                        }
                        .onExitCommand {
                            isAddingFolder = false
                            newFolderName = ""
                        }
                }
            }
            
            // Tags Section
            if !tags.isEmpty {
                Section("Tags") {
                    ForEach(tags) { tag in
                        SidebarRow(item: .tag(tag), count: tagCount(tag))
                            .tag(SidebarItem.tag(tag))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .frame(minWidth: 200)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 6) {
                Image("DriftLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                Text("Drift")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .toolbar {
            ToolbarItem {
                Button(action: { isAddingFolder = true }) {
                    Image("folder-plus")
                }
                .help("New Folder")
            }
        }
        .onAppear {
            createDefaultFoldersIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewFolder)) { _ in
            isAddingFolder = true
        }
    }
    
    private func createFolder() {
        guard !newFolderName.isEmpty else {
            isAddingFolder = false
            return
        }
        
        let folder = Folder(name: newFolderName)
        modelContext.insert(folder)
        
        newFolderName = ""
        isAddingFolder = false
    }
    
    private func deleteFolder(_ folder: Folder) {
        modelContext.delete(folder)
    }
    
    private func createDefaultFoldersIfNeeded() {
        guard folders.isEmpty else { return }
        
        for folder in Folder.createDefaultFolders() {
            modelContext.insert(folder)
        }
    }
}

#Preview {
    SidebarView(appState: AppState())
        .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}
