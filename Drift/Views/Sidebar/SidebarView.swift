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
    @State private var renamingFolderId: String? = nil
    @State private var renamingFolderName: String = ""
    
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
                    FolderRow(
                        folder: folder,
                        count: folderCount(folder),
                        isRenaming: renamingFolderId == folder.id,
                        renamingName: $renamingFolderName,
                        onDoubleClick: {
                            renamingFolderId = folder.id.uuidString
                            renamingFolderName = folder.name
                        },
                        onRename: {
                            renameFolder(folder)
                        },
                        onRenameCancel: {
                            renamingFolderId = nil
                            renamingFolderName = ""
                        },
                        onDelete: {
                            deleteFolder(folder)
                        },
                        onContextMenuRename: {
                            renamingFolderId = folder.id.uuidString
                            renamingFolderName = folder.name
                        }
                    )
                    .tag(SidebarItem.folder(folder))
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
        .frame(minWidth: 200)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 6) {
                Image(systemName: "wind")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.blue)
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
                    Image(systemName: "folder.badge.plus")
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
    
    private func renameFolder(_ folder: Folder) {
        guard !renamingFolderName.isEmpty else {
            renamingFolderId = nil
            renamingFolderName = ""
            return
        }
        
        folder.name = renamingFolderName
        renamingFolderId = nil
        renamingFolderName = ""
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

// MARK: - Folder Row
struct FolderRow: View {
    let folder: Folder
    let count: Int
    let isRenaming: Bool
    @Binding var renamingName: String
    let onDoubleClick: () -> Void
    let onRename: () -> Void
    let onRenameCancel: () -> Void
    let onDelete: () -> Void
    let onContextMenuRename: () -> Void
    
    var body: some View {
        if isRenaming {
            TextField("Folder name", text: $renamingName)
                .textFieldStyle(.plain)
                .onSubmit(onRename)
                .onExitCommand(onRenameCancel)
        } else {
            SidebarRow(item: .folder(folder), count: count)
                .onDoubleClick {
                    onDoubleClick()
                }
                .contextMenu {
                    Button("Rename", systemImage: "pencil") {
                        onContextMenuRename()
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        onDelete()
                    }
                }
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
                Image(systemName: item.icon)
                    .foregroundStyle(item.color)
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

#Preview {
    SidebarView(appState: AppState())
        .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}
