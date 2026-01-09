# Development Guide

## Getting Started

### Prerequisites

- **macOS 14.0** (Sonoma) or later
- **Xcode 15.0** or later
- **Git** for version control
- **GitHub account** (for contributing)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/davidelvar/Drift.git
   cd Drift
   ```

2. **Open in Xcode:**
   ```bash
   open Drift.xcodeproj
   ```

3. **Select build target:**
   - Scheme: `Drift`
   - Destination: `My Mac`

4. **Build and run:**
   - Press `⌘R` or click the Play button
   - Wait for the build to complete
   - Drift will launch automatically

## Project Dependencies

### Swift Packages

Drift uses the following external Swift packages:

- **swift-markdown** - Markdown parsing
- **Splash** - Syntax highlighting for code blocks
- **MarkdownUI** - Markdown rendering in SwiftUI
- **STTextView** - Advanced text view for macOS

These are automatically managed by Xcode's Swift Package Manager (SPM).

## Development Workflow

### 1. Creating a New Feature

```bash
# Create a feature branch
git checkout -b feature/my-awesome-feature

# Make your changes
# Test thoroughly

# Commit with descriptive messages
git commit -m "Add awesome feature

- Added X functionality
- Improved Y performance
- Fixed Z bug"

# Push to your fork
git push origin feature/my-awesome-feature
```

### 2. Testing Your Changes

- **Build** - Ensure the project builds without errors
- **Run** - Test the app manually
- **Test** - Use Xcode's testing framework for unit tests

### 3. Code Review

Before submitting a PR:
- [ ] Code follows Swift style guidelines
- [ ] Changes are well-documented
- [ ] No debug prints in production code
- [ ] Tested on macOS 14.0+

## Code Style Guidelines

### Naming Conventions

```swift
// Classes, structs, enums - PascalCase
class NoteService { }
struct Note { }
enum EditorMode { }

// Properties, variables, functions - camelCase
var selectedNote: Note?
func saveNote(_ note: Note) { }

// Constants - UPPER_SNAKE_CASE or camelCase
let DEFAULT_FONT_SIZE = 14
let maxNoteSize = 1_000_000
```

### File Organization

Use `// MARK:` to organize code:

```swift
struct NoteListView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @State private var searchQuery = ""
    
    // MARK: - Body
    var body: some View {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func filterNotes() { }
    
    // MARK: - Previews
    #Preview { }
}
```

### SwiftUI Best Practices

```swift
// Use @Observable instead of @EnvironmentObject
@Observable
final class AppState {
    var selectedNote: Note?
}

// Use @Query for reactive data binding
struct NoteListView: View {
    @Query(sort: \Note.updatedAt, order: .reverse) var notes: [Note]
}

// Use @Binding for child view updates
struct NoteRowView: View {
    @Binding var note: Note
}

// Use @State for local state only
struct EditorView: View {
    @State private var isEditing = false
}
```

### Comments

```swift
// Clear, concise comments explaining "why", not "what"

// GOOD: Explains the reasoning
// We debounce search to avoid excessive database queries
// as the user types rapidly
@State private var searchTask: Task<Void, Never>?

// BAD: Obvious from code
// Set selectedNote to the first note
selectedNote = notes.first
```

## Building and Running

### Development Build
```bash
# In Xcode, select Debug configuration
⌘R to build and run
```

### Release Build
```bash
# In Xcode, select Release configuration
⌘B to build
```

### Cleaning Build Artifacts
```bash
# Clear Xcode cache
rm -rf ~/Library/Developer/Xcode/DerivedData/Drift-*

# Or in Xcode: ⌘⇧K
```

## Debugging

### Xcode Debugger

```swift
// Set a breakpoint on a line and use lldb
// In Xcode console:
(lldb) po selectedNote  // Print object
(lldb) p searchQuery    // Print variable
```

### Logging

```swift
import os

let logger = Logger(subsystem: "com.drift.app", category: "editor")

logger.info("Note saved")
logger.debug("Search took \(duration)ms")
logger.error("Failed to save: \(error.localizedDescription)")
```

### View Debugging

In Xcode:
1. Run the app
2. Debug → View Hierarchy
3. Inspect SwiftUI views and their properties

## SwiftData Debugging

### Inspecting the Database

```swift
// Print all notes
let descriptor = FetchDescriptor<Note>()
let notes = try? modelContext.fetch(descriptor)
print("Total notes: \(notes?.count ?? 0)")

// Print a specific note
if let note = selectedNote {
    print("Note ID: \(note.id)")
    print("Title: \(note.title)")
    print("Folder: \(note.folder?.name ?? "None")")
}
```

## Common Issues and Solutions

### Issue: Build fails with "module not found"
```bash
# Solution: Clean build folder
rm -rf DerivedData
⌘⇧K in Xcode
```

### Issue: Preview not updating
```bash
# Solution: Resume previews or reload
⌘⇧⌘P in Xcode canvas
```

### Issue: SwiftData model changes
```swift
// When adding/removing properties, Xcode handles migration
// If issues persist, delete the app and rebuild
```

### Issue: Git conflicts in project.pbxproj
```bash
# This file is auto-generated, usually safe to resolve by:
git checkout --ours Drift.xcodeproj/project.pbxproj
```

## Testing

### Unit Tests

```swift
import XCTest
@testable import Drift

class NoteServiceTests: XCTestCase {
    var service: NoteService!
    
    override func setUp() {
        super.setUp()
        service = NoteService()
    }
    
    func testCreateNote() {
        let note = service.createNote(title: "Test")
        XCTAssertEqual(note.title, "Test")
    }
}
```

Run tests:
- In Xcode: `⌘U`
- In terminal: `xcodebuild test -scheme Drift`

## Documentation

When adding new features:
1. Update relevant documentation files
2. Add inline code comments for complex logic
3. Update [ARCHITECTURE.md](ARCHITECTURE.md) if structure changes
4. Update [README.md](../README.md) if it's a user-facing feature

## Performance Tips

- Use `.id()` modifier on list items for better performance
- Debounce search queries
- Load images lazily
- Use `@Query` with filters to reduce data
- Profile with Instruments (⌘I)

## Resources

- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Guide](https://developer.apple.com/documentation/swiftdata)
- [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Xcode Help](https://help.apple.com/xcode/)

## Getting Help

- **GitHub Issues** - Report bugs or ask questions
- **GitHub Discussions** - General questions and ideas
- **Pull Requests** - Share your improvements
