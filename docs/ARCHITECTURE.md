# Architecture Guide

## Overview

Drift is built with a clean MVVM (Model-View-ViewModel) architecture optimized for SwiftUI. This guide explains the structure and design decisions.

## Project Structure

```
Drift/
├── DriftApp.swift                 # App entry point
├── ContentView.swift              # Main layout
├── Models/
│   ├── Note.swift                 # Note data model
│   ├── Folder.swift               # Folder organization
│   └── Tag.swift                  # Tag system
├── Views/
│   ├── Sidebar/
│   │   └── SidebarView.swift      # Navigation sidebar
│   ├── NoteList/
│   │   ├── NoteListView.swift     # Note list and search
│   │   └── NoteRowView.swift      # Individual note row
│   └── Editor/
│       ├── NoteEditorView.swift   # Note editor
│       ├── MarkdownRenderer.swift # Markdown preview
│       └── FocusModeView.swift    # Full-screen writing
├── ViewModels/
│   └── AppState.swift             # Central state management
├── Services/
│   ├── NoteService.swift          # Data operations
│   └── MarkdownHighlighter.swift  # Syntax highlighting
├── Plugins/
│   └── Plugin.swift               # Plugin system
└── Extensions/
    ├── Date+Extensions.swift      # Date utilities
    └── String+Extensions.swift    # String utilities
```

## Data Model (SwiftData)

### Note
The core model representing a note.

```swift
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
    var folder: Folder?
    var tags: [Tag]
}
```

### Folder
Hierarchical organization of notes.

```swift
@Model
final class Folder {
    var id: UUID
    var name: String
    var icon: String
    var notes: [Note]
    var sortOrder: Int
}
```

### Tag
Flexible tagging system with colors.

```swift
@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String // Hex color code
    var notes: [Note]
}
```

## State Management

### AppState (@Observable)
Central state container using the new `@Observable` macro.

Key properties:
- `selectedNote` - Currently edited note
- `selectedSidebarItem` - Active folder/tag/collection
- `searchQuery` - Current search text
- `editorMode` - Edit/Preview/Split mode
- `isFocusMode` - Full-screen writing mode

```swift
@Observable
final class AppState {
    var selectedNote: Note?
    var selectedSidebarItem: SidebarItem = .allNotes
    var searchQuery: String = ""
    var editorMode: EditorMode = .edit
    var isFocusMode: Bool = false
    
    // ... more properties and methods
}
```

## View Hierarchy

### ContentView (NavigationSplitView)
Three-column layout:
1. **Sidebar** - Folders, tags, collections
2. **NoteList** - Search and list of notes
3. **Editor** - Note content editing

### NoteEditorView
Main editing interface with:
- Formatting toolbar
- Editor view (using NSViewRepresentable for NSTextView)
- Markdown preview/split view
- Inspector panel for metadata

### NoteListView
Displays filtered and sorted notes with:
- Search bar
- Sort options
- Note rows with preview
- Context menu actions

### SidebarView
Navigation with:
- Quick access collections (All Notes, Favorites, Archive, Trash)
- Folder tree
- Tag list
- Folder/tag management UI

## Key Design Patterns

### NSViewRepresentable Bridge
The editor uses `NSTextView` wrapped in `NSViewRepresentable` for better control over text rendering and performance.

```swift
struct STTextViewRepresentable: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSView {
        // Create and configure NSTextView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update when state changes
    }
}
```

### Coordinator Pattern
The `Coordinator` class bridges NSTextView delegate callbacks to SwiftUI state.

```swift
class Coordinator: NSObject, NSTextViewDelegate {
    var textBinding: Binding<String>
    
    func textDidChange(_ notification: Notification) {
        // Update binding when text changes
        textBinding.wrappedValue = textView.string
    }
}
```

### Binding Synchronization
When switching notes, the coordinator binding is updated in `updateNSView()` to ensure it points to the current note's content.

## Data Flow

1. **User Action** (e.g., selecting a note)
2. **AppState Update** (selectedNote property)
3. **View Update** (SwiftUI re-renders)
4. **Data Persistence** (SwiftData saves automatically)

## Persistence

SwiftData handles all data persistence automatically:
- Models decorated with `@Model` are automatically persisted
- Changes are saved to the local SwiftData store
- Queries use `@Query` macro for reactive updates

## Performance Considerations

- **Editor** - Uses native `NSTextView` for better performance with large documents
- **Markdown Rendering** - Only updates when content changes
- **Search** - Debounced and filtered efficiently
- **List Rendering** - Uses `List` with `id` for optimal performance

## Future Extensibility

The plugin system allows third-party extensions without modifying core code. See [Plugin System](../README.md#🔌-plugin-system) for details.
