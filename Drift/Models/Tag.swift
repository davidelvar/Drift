//
//  Tag.swift
//  Drift
//
//  A beautiful, extensible notes app for macOS
//

import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String
    var createdAt: Date
    
    // Relationships
    var notes: [Note]
    
    // Computed properties
    var noteCount: Int {
        notes.filter { !$0.isTrashed }.count
    }
    
    init(name: String, color: String = "gray") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.notes = []
    }
}

// MARK: - Tag Helpers
extension Tag {
    static let defaultColors = [
        "red", "orange", "yellow", "green", "mint",
        "teal", "cyan", "blue", "indigo", "purple",
        "pink", "brown", "gray"
    ]
}
