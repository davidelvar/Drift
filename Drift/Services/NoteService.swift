//
//  NoteService.swift
//  Drift
//
//  Service layer for note operations
//

import Foundation
import SwiftData

@MainActor
final class NoteService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    func createNote(title: String = "Untitled", content: String = "", folder: Folder? = nil) -> Note {
        let note = Note(title: title, content: content, folder: folder)
        modelContext.insert(note)
        return note
    }
    
    func deleteNote(_ note: Note) {
        modelContext.delete(note)
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    // MARK: - Queries
    
    func fetchAllNotes() throws -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { !$0.isTrashed && !$0.isArchived }
        )
        let notes = try modelContext.fetch(descriptor)
        // Sort in memory: pinned first, then by most recently updated
        return notes.sorted { n1, n2 in
            if n1.isPinned != n2.isPinned { return n1.isPinned }
            return n1.updatedAt > n2.updatedAt
        }
    }
    
    func fetchFavorites() throws -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.isPinned && !$0.isTrashed }
        )
        let notes = try modelContext.fetch(descriptor)
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func fetchArchived() throws -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.isArchived && !$0.isTrashed }
        )
        let notes = try modelContext.fetch(descriptor)
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func fetchTrashed() throws -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.isTrashed }
        )
        let notes = try modelContext.fetch(descriptor)
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func fetchNotes(in folder: Folder) throws -> [Note] {
        let folderId = folder.id
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.folder?.id == folderId && !$0.isTrashed }
        )
        let notes = try modelContext.fetch(descriptor)
        return notes.sorted { n1, n2 in
            if n1.isPinned != n2.isPinned { return n1.isPinned }
            return n1.updatedAt > n2.updatedAt
        }
    }
    
    func searchNotes(query: String) throws -> [Note] {
        guard !query.isEmpty else { return try fetchAllNotes() }
        
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate {
                !$0.isTrashed && (
                    $0.title.localizedStandardContains(query) ||
                    $0.content.localizedStandardContains(query)
                )
            }
        )
        let notes = try modelContext.fetch(descriptor)
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }
}
