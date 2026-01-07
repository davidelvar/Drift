//
//  Folder.swift
//  Drift
//
//  A beautiful, extensible notes app for macOS
//

import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var createdAt: Date
    var sortOrder: Int
    
    // Relationships
    var notes: [Note]
    
    @Relationship(inverse: \Folder.children)
    var parent: Folder?
    
    var children: [Folder]
    
    // Computed properties
    var noteCount: Int {
        notes.filter { !$0.isTrashed }.count
    }
    
    var allNotes: [Note] {
        var allNotes = notes
        for child in children {
            allNotes.append(contentsOf: child.allNotes)
        }
        return allNotes
    }
    
    init(
        name: String,
        icon: String = "folder",
        color: String = "blue",
        parent: Folder? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.sortOrder = 0
        self.notes = []
        self.parent = parent
        self.children = []
    }
}

// MARK: - Default Folders
extension Folder {
    static func createDefaultFolders() -> [Folder] {
        [
            Folder(name: "Personal", icon: "person.fill", color: "blue"),
            Folder(name: "Work", icon: "briefcase.fill", color: "orange"),
            Folder(name: "Ideas", icon: "lightbulb.fill", color: "yellow")
        ]
    }
}
