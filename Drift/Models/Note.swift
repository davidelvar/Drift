//
//  Note.swift
//  Drift
//
//  A beautiful, extensible notes app for macOS
//

import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isArchived: Bool
    var isTrashed: Bool
    
    // Relationships
    @Relationship(inverse: \Folder.notes)
    var folder: Folder?
    
    @Relationship(inverse: \Tag.notes)
    var tags: [Tag]
    
    // Computed properties
    var preview: String {
        let stripped = content.replacingOccurrences(of: #"[#*_`~\[\]()]"#, with: "", options: .regularExpression)
        return String(stripped.prefix(150))
    }
    
    var wordCount: Int {
        content.split(separator: " ").count
    }
    
    var characterCount: Int {
        content.count
    }
    
    init(
        title: String = "Untitled",
        content: String = "",
        folder: Folder? = nil,
        tags: [Tag] = []
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPinned = false
        self.isArchived = false
        self.isTrashed = false
        self.folder = folder
        self.tags = tags
    }
    
    func update(title: String? = nil, content: String? = nil) {
        if let title = title {
            self.title = title
        }
        if let content = content {
            self.content = content
        }
        self.updatedAt = Date()
    }
    
    func moveToTrash() {
        self.isTrashed = true
        self.updatedAt = Date()
    }
    
    func restore() {
        self.isTrashed = false
        self.updatedAt = Date()
    }
    
    func togglePin() {
        self.isPinned.toggle()
        self.updatedAt = Date()
    }
    
    func archive() {
        self.isArchived = true
        self.updatedAt = Date()
    }
}
