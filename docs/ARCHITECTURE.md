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

## Swift API Design Guidelines

Drift adheres to [Swift's API Design Guidelines](https://swift.org/documentation/api-design-guidelines/), which shape how we structure and name code throughout the project. These guidelines emphasize clarity, consistency, and fluent usage—all critical for a codebase that evolves with community contributions.

### Clarity at the Point of Use

**Principle**: Names should make sense when read in context, not just when declared.

**In Drift**:
- Method names clearly indicate their behavior: `note.togglePin()` instead of `note.pin()`
- Property names avoid redundant type information: `selectedNote` instead of `noteSelection`
- Binding parameters are descriptive: `.onChange(of: note.id)` explicitly shows what's being observed

```swift
// ✅ Clear at use site - behavior is obvious
selectedNote.moveToTrash()
folder.addNote(newNote)

// ❌ Would be ambiguous
selectedNote.trash()  // delete or move to trash?
folder.add(newNote)   // add what?
```

### Naming Conventions

**Case Conventions**: Drift follows Swift conventions:
- **Types** (classes, structs, enums): `PascalCase` → `Note`, `AppState`, `EditorMode`
- **Everything else**: `camelCase` → `selectedNote`, `editorMode`, `saveNote()`

```swift
// Types in PascalCase
class NoteService { }
struct Note { }
enum SidebarItem { }

// Properties and methods in camelCase
var selectedNote: Note?
func archiveNote(_ note: Note) { }
```

### Fluent Usage

**Principle**: Code should read like natural language.

**In Drift**:
- Methods read as imperative phrases: `note.togglePin()`, `folder.addNote(_:)`
- Boolean properties read as assertions: `note.isPinned`, `note.isArchived`
- Mutating methods have clear imperative names: `note.moveToTrash()` vs non-mutating `noteTrashedCopy()`

```swift
// ✅ Reads naturally
note.togglePin()          // "toggle the note's pin state"
if note.isPinned { }      // "if the note is pinned"
note.extractedTitle       // "the note's extracted title"

// ❌ Would be awkward
note.changePinState()
if note.pinnedState == true { }
note.title_extracted
```

### Mutating vs. Non-Mutating Method Pairs

When an operation can modify a value or return a new one, Drift follows the guideline of using consistent naming:

```swift
// Hypothetical examples following guidelines:
// Mutating: imperative verb
// Non-mutating: verb + "ed" or "ing"

var content = "HELLO"
content.lowercase()           // mutates in place
let lower = content.lowercased()  // returns new value

// Or with noun-based operations:
array.formIntersection(other)  // mutating: "form" prefix
let result = array.intersection(other)  // non-mutating: noun
```

### Avoid Ambiguity

**Principle**: Parameter names and labels should eliminate confusion.

**In Drift**:
- Labels are included when needed: `.padding(.leading, 24)` is clearer than `.padding(24, .leading)`
- Generic parameters avoid overloading: When methods could mean different things with polymorphic types, we name explicitly

```swift
// ✅ Clear what each parameter means
noteView.padding(.horizontal, 8)
.padding(.vertical, 6)

// Include type information when types are weak
func addObserver(_ observer: NSObject, forKeyPath path: String)
// Much clearer than: func add(_ observer: NSObject, _ path: String)
```

### Documentation Comments

Following Swift conventions, public APIs in Drift are documented with clear, concise comments:

```swift
/// Moves the note to the trash.
/// 
/// This operation is reversible through the trash collection.
/// To permanently delete, use `deletePermanently()`.
func moveToTrash() { }

/// Returns `true` if the note has been pinned to favorites.
var isPinned: Bool { }

/// Creates a new note in the specified folder.
///
/// - Parameter folder: The destination folder. If `nil`, the note 
///   is created at the root level.
/// - Returns: The newly created note.
init(title: String, in folder: Folder?) { }
```

### Terminology Choices

**Principle**: Use established terms from the domain, not invented ones.

**In Drift**:
- `Folder` instead of `Directory` or `Container` - familiar to users
- `Archive` instead of `Store` or `Vault` - standard in note-taking apps
- `Trash` instead of `Delete Bin` or `Recycle` - consistent across platforms
- `Markdown` instead of `Markup Format` - established technical term
- `Tag` instead of `Label` or `Category` - clear and concise

### Side Effects in Naming

**Principle**: Names should indicate whether an operation has side effects.

**In Drift**:
- **No side effects** (noun phrases): `note.preview`, `note.extractedTitle`
- **Side effects** (imperative verbs): `note.moveToTrash()`, `folder.delete()`
- Boolean getters/properties: `note.isPinned`, `note.isTrashed`

```swift
// ✅ Method names clearly show side effects
note.moveToTrash()        // imperative - has side effect
folder.archiveNotes()     // imperative - mutates state

// ✅ Computed properties show no side effects
note.preview              // noun - read-only
note.extractedTitle       // noun - derived value
note.wordCount            // noun - calculated property
```

### Default Parameters Over Method Families

Following Swift's preference for defaults, Drift uses parameter defaults instead of creating multiple similar methods:

```swift
// ✅ Single method with sensible defaults
func search(query: String, inFolder: Folder? = nil, sort: SortOrder = .updatedAt) { }

// Instead of multiple overloads:
// func search(_ query: String) { }
// func search(_ query: String, inFolder: Folder) { }
// func search(_ query: String, inFolder: Folder, sort: SortOrder) { }
```

### Impact on Drift's Codebase

These guidelines influence several key aspects:

1. **Consistency** - All developers can predict method/property names
2. **Discoverability** - Code reads like documentation
3. **Maintainability** - New contributors understand naming patterns immediately
4. **Quality** - Forces thoughtful API design decisions
5. **Integration** - Code feels like native Swift, not foreign

By adhering to these guidelines, Drift maintains a professional, accessible codebase that welcomes contributors and feels familiar to Swift developers.
