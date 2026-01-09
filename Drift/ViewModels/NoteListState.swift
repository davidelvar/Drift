//
//  NoteListState.swift
//  Drift
//
//  Note list view state management
//

import Foundation
import SwiftUI
import SwiftData

@Observable
final class NoteListState {
    var searchQuery: String = ""
    var selectedNote: Note?
    var sortOrder: NoteSortOrder = .updatedDesc
    
    init() {}
    
    func setSearchQuery(_ query: String) {
        searchQuery = query
    }
    
    func selectNote(_ note: Note?) {
        selectedNote = note
    }
    
    func setSortOrder(_ order: NoteSortOrder) {
        sortOrder = order
    }
}

enum NoteSortOrder: String, CaseIterable {
    case titleAsc = "Title (A-Z)"
    case titleDesc = "Title (Z-A)"
    case updatedDesc = "Recently Modified"
    case updatedAsc = "Oldest First"
    case createdDesc = "Recently Created"
    case createdAsc = "Oldest Created"
    
    var sortDescriptor: SortDescriptor<Note> {
        switch self {
        case .titleAsc:
            return SortDescriptor(\.title)
        case .titleDesc:
            return SortDescriptor(\.title, order: .reverse)
        case .updatedDesc:
            return SortDescriptor(\.updatedAt, order: .reverse)
        case .updatedAsc:
            return SortDescriptor(\.updatedAt)
        case .createdDesc:
            return SortDescriptor(\.createdAt, order: .reverse)
        case .createdAsc:
            return SortDescriptor(\.createdAt)
        }
    }
}
