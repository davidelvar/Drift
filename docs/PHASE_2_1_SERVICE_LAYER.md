# Phase 2.1: Service Layer Refactoring
## Project Management Document

**Status**: Planning Complete - Implementation Ready  
**Date**: January 8, 2026  
**Duration**: 8-9 days (1.5-2 weeks)  
**Owner**: Architecture Team  
**Version**: 1.0  

---

## Executive Summary

Phase 2.1 consolidates 30+ direct model mutations scattered across views into three dedicated, protocol-based services (NoteRelationshipService, FolderService, TagService). This establishes a clean separation of concerns, enables testability through dependency injection, and provides the foundation for Phase 2.2 (Command Pattern) and future features (undo/redo, remote sync, offline mode).

**Key Metric**: 85%+ test coverage for services; zero breaking changes to views.

---

## Architecture Overview

### Service Locator Pattern (AppState)

All services are accessed through AppState, consistent with Phase 1 state management refactoring:

```swift
@Observable
final class AppState {
    // Services (NEW in Phase 2.1)
    var noteRelationshipService: NoteRelationshipService
    var folderService: FolderService
    var tagService: TagService
    
    init(modelContext: ModelContext) {
        self.noteRelationshipService = NoteRelationshipService(modelContext: modelContext)
        self.folderService = FolderService(modelContext: modelContext)
        self.tagService = TagService(modelContext: modelContext)
    }
}

// Usage in views:
appState.noteRelationshipService.toggleFavorite(note)
appState.folderService.createFolder(name: "Work")
appState.tagService.createTag(name: "Important", color: "red")
```

### Dependency Diagram

```
┌─────────────────┐
│    Views        │
│ (NoteListView,  │
│ NoteEditorView) │
└────────┬────────┘
         │ uses
         ▼
┌─────────────────────────────────┐
│      AppState (ServiceLocator)  │
├─────────────────────────────────┤
│ • noteRelationshipService       │
│ • folderService                 │
│ • tagService                    │
└────┬────────────────┬──────────┬┘
     │                │          │
     ▼                ▼          ▼
┌──────────────┐ ┌──────────┐ ┌─────────┐
│NoteRel.Svc   │ │FolderSvc │ │TagSvc   │
├──────────────┤ ├──────────┤ ├─────────┤
│ 16 methods   │ │10 methods│ │12 method│
│ (atomic ops) │ │(hierarchy)│ │(dedup)  │
└──────┬───────┘ └─────┬────┘ └────┬────┘
       │               │           │
       └───────────────┼───────────┘
                       ▼
              ┌─────────────────┐
              │ Models (Note,   │
              │ Folder, Tag)    │
              └─────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ SwiftData       │
              │ ModelContext    │
              └─────────────────┘
```

### Protocol Definitions

All services conform to one or more of these protocols for testability:

```swift
protocol DataService: AnyObject, Sendable {
    associatedtype Model
    @MainActor func save() throws
    @MainActor func fetch() throws -> [Model]
}

protocol RelationshipService: AnyObject, Sendable {
    @MainActor func addRelationship(_ target: AnyObject) throws
    @MainActor func removeRelationship(_ target: AnyObject) throws
    @MainActor func updateRelationship(_ target: AnyObject, _ newTarget: AnyObject?) throws
}

protocol Searchable: AnyObject, Sendable {
    associatedtype SearchResult
    @MainActor func search(query: String) throws -> [SearchResult]
}

protocol Validatable: AnyObject, Sendable {
    associatedtype ValidatableType
    @MainActor func validate(_ model: ValidatableType) throws
}
```

---

## Implementation Plan

### Step 1: Create Service Protocols (Day 0.5)

**File**: `Drift/Services/Protocols.swift`  
**Responsible**: Architecture Lead  
**Est. Hours**: 2  

Create base protocols with `@MainActor` and `Sendable` for thread safety. All services conform to these to enable testing and future extensibility.

#### Deliverables
- [x] DataService protocol
- [x] RelationshipService protocol
- [x] Searchable protocol
- [x] Validatable protocol
- [x] Documentation comments

---

### Step 2: Update AppState Integration (Day 0.5)

**File**: `Drift/ViewModels/AppState.swift`  
**Responsible**: State Management Lead  
**Est. Hours**: 2  

Add three service properties to AppState. Initialize services with ModelContext in init(). Maintain backward compatibility.

#### Changes
- Add properties: `noteRelationshipService`, `folderService`, `tagService`
- Initialize in `init(modelContext:)`
- Add getter methods for service access
- Update DriftApp.swift to pass ModelContext to AppState

---

### Step 3: NoteRelationshipService (Days 1-3)

**File**: `Drift/Services/NoteRelationshipService.swift`  
**Responsible**: Core Services Lead  
**Est. Hours**: 16-18  
**Complexity**: Medium  
**LOC**: 350-400  

Atomic operations on notes with automatic timestamp management.

#### Methods (16 total)

**Favorite Management** (3)
- `toggleFavorite(_ note: Note) throws`
- `markFavorite(_ note: Note) throws`
- `unmarkFavorite(_ note: Note) throws`

**Trash Management** (3)
- `moveToTrash(_ note: Note) throws`
- `restoreFromTrash(_ note: Note) throws`
- `permanentlyDelete(_ note: Note) throws`

**Archive Management** (2)
- `archive(_ note: Note) throws`
- `unarchive(_ note: Note) throws`

**Folder Operations** (3)
- `assignFolder(_ note: Note, to folder: Folder) throws`
- `removeFromFolder(_ note: Note) throws`
- `moveToFolder(_ note: Note, to newFolder: Folder) throws`

**Tag Operations** (5)
- `addTag(_ note: Note, _ tag: Tag) throws`
- `removeTag(_ note: Note, _ tag: Tag) throws`
- `setTags(_ note: Note, to tags: [Tag]) throws`
- `clearTags(_ note: Note) throws`
- `clearTagsFromNoteBatch(_ notes: [Note]) throws`

**Batch Operations** (2)
- `toggleFavoriteBatch(_ notes: [Note]) throws`
- `moveToTrashBatch(_ notes: [Note]) throws`

#### Error Types
```swift
enum NoteRelationshipError: LocalizedError {
    case invalidNote
    case cannotArchiveTrashedNote
    case cannotDeleteNonTrashedNote
    case tagAlreadyAssigned
}
```

#### View Integration Map
| View | Line(s) | Current | Service Method |
|------|---------|---------|----------------|
| NoteEditorView | 170 | `note.togglePin()` | `toggleFavorite()` |
| NoteListView | 183 | `note.togglePin()` | `toggleFavorite()` |
| NoteListView | 210 | `note.archive()` | `archive()` |
| NoteListView | 216 | `note.moveToTrash()` | `moveToTrash()` |
| NoteListView | 223 | `note.restore()` | `restoreFromTrash()` |
| NoteEditorView | 364 | `removeTag(tag)` | `removeTag()` |
| NoteEditorView | 376 | `assignTag(tag)` | `addTag()` |

#### Test Coverage
- 18 unit tests covering all methods and error conditions

---

### Step 4: FolderService (Days 4-5, parallel with TagService)

**File**: `Drift/Services/FolderService.swift`  
**Responsible**: Hierarchy Lead  
**Est. Hours**: 12-14  
**Complexity**: Medium-High (hierarchy logic)  
**LOC**: 280-320  

Complete folder CRUD with hierarchical nesting. **Cascade Strategy**: Move notes to parent folder (safe, preserves data).

#### Methods (10 total)

**CRUD** (5)
- `createFolder(name: String, icon: String, color: String, parent: Folder?) throws -> Folder`
- `deleteFolder(_ folder: Folder) throws` (cascade: notes → parent)
- `renameFolder(_ folder: Folder, to newName: String) throws`
- `moveFolder(_ folder: Folder, to newParent: Folder?) throws`
- `updateFolderAppearance(_ folder: Folder, icon: String?, color: String?) throws`

**Query** (5)
- `fetchFolders() throws -> [Folder]`
- `fetchFolder(id: UUID) throws -> Folder?`
- `fetchRootFolders() throws -> [Folder]`
- `fetchAllDescendants(_ folder: Folder) -> [Folder]`
- `updateSortOrder(_ folder: Folder, to newOrder: Int) throws`

#### Cascade Deletion Logic
```
User deletes "Work" folder
    ↓
For each note in "Work":
    note.folder = "Work".parent  // move to parent (or nil if root)
For each child folder:
    child.parent = "Work".parent // promote to parent level
Delete "Work" folder
    ↓
Result: All data preserved, hierarchy maintained
```

#### Error Types
```swift
enum FolderServiceError: LocalizedError {
    case folderNotFound(UUID)
    case duplicateFolderName(String)
    case invalidFolderName
    case cannotDeleteDefaultFolder
    case folderHierarchyError
}
```

#### Validation Rules
- Folder name: non-empty, ≤255 chars, no invalid path chars (`/\:|*?<>"`)
- Duplicate names: case-insensitive, checked at same hierarchy level
- Default folders: Personal, Work, Ideas (cannot delete)
- Hierarchy: prevent circular references

#### Test Coverage
- 12 unit tests covering CRUD, hierarchy, and cascades

---

### Step 5: TagService (Days 5-6, parallel with FolderService)

**File**: `Drift/Services/TagService.swift`  
**Responsible**: Tag Management Lead  
**Est. Hours**: 10-12  
**Complexity**: Medium  
**LOC**: 280-320  

Tag CRUD with case-insensitive deduplication. **Cascade on delete**: Remove tag from all notes.

#### Methods (12 total)

**CRUD** (5)
- `createTag(name: String, color: String?) throws -> Tag`
- `deleteTag(_ tag: Tag) throws` (cascade: remove from all notes)
- `renameTag(_ tag: Tag, to newName: String) throws`
- `updateColor(_ tag: Tag, to newColor: String) throws`
- `mergeTags(_ tag1: Tag, with tag2: Tag) throws`

**Query** (7)
- `fetchAllTags() throws -> [Tag]`
- `fetchTag(id: UUID) throws -> Tag?`
- `fetchTags(for note: Note) -> [Tag]`
- `fetchTagsByUsage() throws -> [Tag]`
- `fetchUnusedTags() throws -> [Tag]`
- `fetchTagsByColor(_ color: String) throws -> [Tag]`
- `search(query: String) throws -> [Tag]` (Searchable conformance)

#### Deduplication Strategy
```
Case-insensitive matching:
• "Important" + "IMPORTANT" = conflict → error
• "Work" + "work" = conflict → error
No auto-rename or silent reuse
```

#### Color Validation
```
Valid colors:
• Preset names: red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray
• Hex format: #RGB or #RRGGBB (e.g., #FF0000, #F00)
Default color: "gray" if not specified
```

#### Error Types
```swift
enum TagServiceError: LocalizedError {
    case tagNotFound(UUID)
    case duplicateTagName(String)
    case invalidTagName
    case invalidColor(String)
}
```

#### Test Coverage
- 14 unit tests covering CRUD, deduplication, and cascades

---

### Step 6: Model Method Deprecation (Day 6)

**File**: `Drift/Models/Note.swift`  
**Responsible**: Models Lead  
**Est. Hours**: 2  

Mark old methods with `@available(deprecated:)` annotations.

#### Changes
```swift
@available(macOS, deprecated: 1.2, message: "Use NoteRelationshipService.toggleFavorite(_:)")
func togglePin() { ... }

@available(macOS, deprecated: 1.2, message: "Use NoteRelationshipService.moveToTrash(_:)")
func moveToTrash() { ... }

@available(macOS, deprecated: 1.2, message: "Use NoteRelationshipService.restoreFromTrash(_:)")
func restore() { ... }

@available(macOS, deprecated: 1.2, message: "Use NoteRelationshipService.archive(_:)")
func archive() { ... }
```

#### Deprecation Path
- **v1.1**: Methods marked deprecated, emit compiler warnings
- **v1.2**: Methods still functional (backward compat window)
- **v1.3**: Methods removed entirely

---

### Step 7: View Refactoring (Days 7-8)

**Files**:
- `Drift/Views/NoteList/NoteListView.swift`
- `Drift/Views/Editor/NoteEditorView.swift`
- `Drift/Views/Sidebar/SidebarView.swift`

**Responsible**: View Refactoring Lead  
**Est. Hours**: 12  
**Scope**: Only directly affected views  
**Deferred**: ContentView.swift → Phase 2.2 (Command Pattern)

#### NoteListView Changes (8 mutations at lines 183, 192, 202, 210, 216, 223, 227, 244, 266)

**Before**:
```swift
note.togglePin()
note.folder = folder
note.archive()
note.moveToTrash()
note.restore()
modelContext.delete(note)
```

**After**:
```swift
try await appState.noteRelationshipService.toggleFavorite(note)
try await appState.noteRelationshipService.moveToFolder(note, to: folder)
try await appState.noteRelationshipService.archive(note)
try await appState.noteRelationshipService.moveToTrash(note)
try await appState.noteRelationshipService.restoreFromTrash(note)
try await appState.noteRelationshipService.permanentlyDelete(note)
```

#### NoteEditorView Changes (lines 170, 364, 376)

**Before**:
```swift
note.togglePin()
removeTag(tag)
assignTag(tag)
```

**After**:
```swift
try await appState.noteRelationshipService.toggleFavorite(note)
try await appState.noteRelationshipService.removeTag(note, tag)
try await appState.noteRelationshipService.addTag(note, tag)
```

#### SidebarView Changes (folder operations)

**Before**:
```swift
let folder = Folder(name: newFolderName)
modelContext.insert(folder)
modelContext.delete(folder)
```

**After**:
```swift
let folder = try await appState.folderService.createFolder(name: newFolderName)
try await appState.folderService.deleteFolder(folder)
```

#### Error Handling Pattern

```swift
Button(action: {
    Task {
        do {
            try await appState.noteRelationshipService.moveToTrash(note)
            appState.selectedNote = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}) {
    Label("Move to Trash", systemImage: "trash")
}
```

---

### Step 8: Testing & Integration (Day 8)

**Responsible**: QA Lead  
**Est. Hours**: 8-10  

#### Unit Tests
- [ ] NoteRelationshipService: 18 tests
- [ ] FolderService: 12 tests
- [ ] TagService: 14 tests
- Total: 44+ tests

#### Integration Tests
- [ ] Cascade deletion (folder → notes)
- [ ] Tag deletion (tag → notes)
- [ ] Folder hierarchy (circular reference prevention)
- [ ] Service initialization via AppState

#### Mock Services
- [ ] MockNoteRelationshipService (for view testing)
- [ ] MockFolderService
- [ ] MockTagService

#### Coverage Target
- [ ] 85%+ coverage for services
- [ ] Zero compiler warnings
- [ ] All tests passing

---

## Implementation Timeline

### Week 1 (Jan 8-12)

| Day | Task | Owner | Est. Hours | Status |
|-----|------|-------|-----------|--------|
| Wed 8 | Protocols + AppState | Architecture | 4 | ☐ |
| Thu 9 | NoteRelationshipService (part 1) | Core Services | 6 | ☐ |
| Fri 10 | NoteRelationshipService (part 2) | Core Services | 6 | ☐ |
| Fri 10 | FolderService (parallel) | Hierarchy | 6 | ☐ |
| Sat 11 | TagService (parallel) | Tag Mgmt | 5 | ☐ |
| Sun 12 | Integration + Testing | QA | 6 | ☐ |

**Total**: 8-9 days, ~40 hours

### Critical Path

```
Protocols + AppState (Day 0.5)
    ↓
NoteRelationshipService (Days 1-3) ← BLOCKS others
    ↓
FolderService + TagService (Days 4-5, parallel)
    ↓
View Refactoring (Days 6-7)
    ↓
Testing + Integration (Day 8)
```

### Parallelization Strategy

- **Protocols + AppState**: 1 person, Day 0.5
- **NoteRelationshipService**: Must complete before next services
- **FolderService + TagService**: 2 people, parallel, Days 4-5
- **View Refactoring**: 1 person, Days 6-7
- **Testing**: 1 person, Day 8

---

## Success Criteria

### Functional Requirements

✅ All 38 service methods implemented with validation  
✅ FolderService handles cascade deletion safely (notes → parent)  
✅ TagService prevents case-insensitive duplicates  
✅ AppState initializes services via ModelContext  
✅ Protocols enable testability (mock services working)  
✅ Old model methods deprecated but functional  
✅ Zero breaking changes to existing views  

### Quality Requirements

✅ 85%+ unit test coverage for services  
✅ All public methods documented with examples  
✅ Error types descriptive and user-facing  
✅ Thread safety: @MainActor on all mutable operations  
✅ No compiler warnings when using new services  
✅ Deprecation warnings on old methods  
✅ Integration tests for cascading operations  

### Regression Testing

✅ All existing keyboard shortcuts still functional  
✅ All existing UI interactions unchanged  
✅ No data loss on folder/tag operations  
✅ Timestamps automatically updated by services  
✅ Favorite/trash/archive counts accurate  

---

## Sensible Options (Locked In)

| Decision | Option | Rationale |
|----------|--------|-----------|
| **Folder Cascade** | Move notes to parent | Safe, reversible, preserves data |
| **Tag Deduplication** | Case-insensitive, error on duplicate | Prevents hidden issues, import-safe |
| **Error Handling** | Enum types per service, LocalizedError | Type-safe, user-friendly |
| **Service Access** | Via AppState properties | Consistent with Phase 1 |
| **Backward Compat** | Deprecation wrappers (v1.1-v1.3) | Safe migration path |
| **View Scope** | NoteList, NoteEditor, Sidebar only | Reduced scope, reduced risk |
| **ContentView** | Defer to Phase 2.2 | Separates concerns, enables testing |

---

## Risk Analysis & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| NoteRelationshipService delays | Medium | High | Start Day 1, isolate as critical path |
| Cascade deletion loses data | Low | Critical | Extensive testing, move-to-parent strategy |
| Thread safety issues | Low | High | Use @MainActor, test with concurrent access |
| View refactoring breaks UI | Medium | Medium | Keep ContentView unchanged, defer to Phase 2.2 |
| Deprecation warnings overwhelm | Low | Low | Gradual removal (v1.1 → v1.3) |
| Circular folder hierarchies | Low | Medium | Add ancestor check in moveFolder() |
| Tag dedup breaks imports | Low | Medium | Document conflict handling strategy |

### Mitigation Strategies

1. **Start NoteRelationshipService immediately** — blocks other services
2. **Extensive cascade deletion testing** — most destructive operation
3. **Defer ContentView changes** — reduces scope, reduces risk
4. **Keep old model methods functional** — backward compat safety net
5. **Thread safety validation** — use async/await properly in views
6. **Ancestor check before moveFolder()** — prevent circular hierarchies

---

## Post-Implementation Checklist

### Code Quality
- [ ] All services conform to protocols
- [ ] No force-unwraps in service code
- [ ] All errors properly documented
- [ ] Code review: 2 approvals minimum
- [ ] Lint: zero warnings

### Testing
- [ ] Unit tests: 18 + 12 + 14 = 44 tests minimum
- [ ] Integration tests for cascades
- [ ] Mock services for view testing
- [ ] Code coverage: 85%+ target
- [ ] CI/CD: all tests passing

### Documentation
- [ ] Protocol definitions documented
- [ ] Each service method has examples
- [ ] Error types explained with solutions
- [ ] Deprecation path documented
- [ ] View integration guide created

### UI/UX
- [ ] No visual regressions
- [ ] Error messages user-friendly
- [ ] Loading states for async operations
- [ ] Undo hint messages (prepare for Phase 2.2)

### Deployment
- [ ] Version bumped to 1.1
- [ ] Release notes prepared
- [ ] Deprecated methods highlighted
- [ ] Beta testing on 5+ users
- [ ] No crashes in telemetry

---

## Dependencies & Integration Points

### External Dependencies
None — services use only SwiftData and Foundation

### Internal Dependencies
```
NoteRelationshipService
  ↓
  Uses: ModelContext, Note, Folder, Tag models
  Optional: NoteService (for queries)

FolderService
  ↓
  Uses: ModelContext, Folder, Note models
  Calls: NoteRelationshipService (for note reassignment)

TagService
  ↓
  Uses: ModelContext, Tag, Note models
  Calls: NoteRelationshipService (optional)
```

### Phase Dependencies
- **Phase 2.1** → Phase 2.2 (Command Pattern uses these services)
- **Phase 2.1** → Phase 2.3+ (Undo/redo, remote sync, offline mode)

---

## Future Enhancements

### Phase 2.2: Command Pattern (Week 3)
Use NoteRelationshipService as foundation for:
- Typed command objects
- Undo/redo stack
- Command history/audit trail
- Keyboard shortcut routing

### Phase 2.3: Advanced Search (Week 4)
Extract to SearchService:
- Boolean queries (AND/OR/NOT)
- Date range filtering
- Tag-based filtering
- Folder-scoped searches
- Saved searches

### Phase 2.4: Sync & Offline (Future)
Services provide foundation:
- Protocol-based store abstraction
- Swap implementations (local ↔ remote)
- Sync conflict resolution
- Offline queuing

---

## Code Templates

### Service Template

```swift
import Foundation
import SwiftData

@MainActor
final class MyService: DataService {
    typealias Model = MyModel
    
    private let modelContext: ModelContext
    
    enum Error: LocalizedError {
        case someError
        var errorDescription: String? { "Error description" }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    func fetch() throws -> [MyModel] {
        let descriptor = FetchDescriptor<MyModel>()
        return try modelContext.fetch(descriptor)
    }
}
```

### Test Template

```swift
import XCTest
@testable import Drift

final class MyServiceTests: XCTestCase {
    var sut: MyService!
    var mockContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        mockContext = MockModelContext()
        sut = MyService(modelContext: mockContext)
    }
    
    func testSomeOperation() throws {
        let item = MyModel()
        try sut.doSomething(item)
        XCTAssertTrue(mockContext.saveCalled)
    }
}
```

### View Integration Template

```swift
Button(action: {
    Task {
        do {
            try await appState.myService.operation(item)
        } catch let error as MyError {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}) {
    Label("Action", systemImage: "star")
}
```

---

## Document History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| Jan 8, 2026 | 1.0 | Architecture | Initial plan |

---

**Status**: ✅ **Ready for Implementation**  
**Next Step**: Begin Step 1 (Protocols) immediately  
**Estimated Completion**: January 17, 2026 (9 days)  
**Reviewers Needed**: 2 (Architecture, QA)
