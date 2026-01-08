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
    
    var extractedTitle: String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        
        // Find highest level heading (lowest # count)
        var highestLevel = 7 // Start higher than h6
        var foundTitle = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check if line starts with # (heading)
            if trimmedLine.hasPrefix("#") {
                let hashCount = trimmedLine.prefix(while: { $0 == "#" }).count
                
                if hashCount < highestLevel {
                    highestLevel = hashCount
                    // Extract text after the # symbols
                    let titleText = trimmedLine
                        .dropFirst(hashCount)
                        .trimmingCharacters(in: .whitespaces)
                    foundTitle = String(titleText)
                }
            }
        }
        
        return foundTitle.isEmpty ? "Untitled" : foundTitle
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
