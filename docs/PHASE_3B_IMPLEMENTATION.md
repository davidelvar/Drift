# Phase 3B: Interactive GFM Features Implementation

**Status:** Starting
**Started:** January 9, 2026
**Target Completion:** January 14, 2026 (5 days)

## Overview

Phase 3B adds interactivity to GFM features introduced in Phase 3A. Users can now click checkboxes, edit tables visually, and interact with extended markdown syntax. This phase builds on the foundation of highlighting and language support.

---

## Phase 3B.1: Task List Interactivity (Days 1-2)

### Objective
Enable users to click task list checkboxes in the editor and toggle between `[ ]` ↔ `[x]` states.

### Architecture

#### 1. TaskListInteractivityManager Service
**Location:** `Drift/Services/TaskListInteractivityManager.swift`

```swift
class TaskListInteractivityManager {
    // Find task list item at mouse position
    func taskListItemAt(in textStorage: NSTextStorage, location: Int) -> TaskListItem?
    
    // Toggle checkbox state ([ ] → [x] → [ ])
    func toggleCheckboxAt(in textStorage: NSTextStorage, range: NSRange) -> Bool
    
    // Find all task lists in document
    func getAllTaskLists(in textStorage: NSTextStorage) -> [TaskList]
    
    // Get percentage complete for a task list
    func getTaskListProgress(items: [TaskListItem]) -> Double
}

struct TaskListItem {
    let range: NSRange              // Range of entire line
    let checkboxRange: NSRange      // Range of [ ] or [x]
    let isCompleted: Bool
    let indentLevel: Int
    let text: String
}

struct TaskList {
    let startIndex: Int
    let items: [TaskListItem]
}
```

#### 2. Editor Integration
**Modify:** `Drift/Views/Editor/SyntaxHighlightedEditor.swift`

- Add `@State private var taskListManager = TaskListInteractivityManager()`
- Override `mouseDown(_:)` to detect task list checkbox clicks
- Call `taskListManager.toggleCheckboxAt()` when checkbox clicked
- Update text storage and sync back to Note model
- Trigger undo/redo registration for checkbox toggles

#### 3. Visual Feedback
- Highlight checkbox area on hover
- Show checkmark animation when toggled
- Update progress indicator if visible
- Play subtle click sound (optional)

### Implementation Details

**Checkbox Detection:**
```
Pattern: ^\s*[-*+]\s+\[([ xX])\]\s+(.*)$
Match groups:
  1. Checkbox state (space or x)
  2. Task text
```

**Toggle Logic:**
- `[ ]` → `[x]` (mark complete)
- `[x]` → `[ ]` (mark incomplete)
- Case-insensitive: handles `[X]` as well

**State Persistence:**
- Changes automatically saved to Note via AppState
- Undo/redo supported through NSUndoManager
- Sync to CoreData/SwiftData

### Success Criteria
- ✅ Click checkbox to toggle state
- ✅ Visual feedback on interaction
- ✅ Undo/redo support
- ✅ Changes persist to Note
- ✅ Works with nested task lists
- ✅ Zero breaking changes

---

## Phase 3B.2: Table Visual Editor (Days 3-5)

### Objective
Provide spreadsheet-like UI for editing GFM tables inline.

### Architecture

#### 1. TableEditorView Component
**Location:** `Drift/Views/Editor/TableEditorView.swift`

```swift
struct TableEditorView: View {
    @Bindable var table: MarkdownTable
    @Environment(\.dismiss) var dismiss
    
    // Visual table grid with editable cells
    var body: some View {
        VStack {
            // Header row (fixed)
            HStack {
                ForEach(table.headers) { column in
                    TableCellEditView(text: column)
                }
            }
            
            // Data rows
            List {
                ForEach(table.rows) { row in
                    TableRowView(row: row)
                }
            }
            
            // Toolbar for row/column operations
            HStack {
                Button(action: { table.insertRow() }) { Label("Insert Row", systemImage: "plus.circle") }
                Button(action: { table.deleteSelectedRow() }) { Label("Delete Row", systemImage: "minus.circle") }
                Button(action: { table.insertColumn() }) { Label("Insert Column", systemImage: "plus.circle") }
                Button(action: { table.deleteSelectedColumn() }) { Label("Delete Column", systemImage: "minus.circle") }
            }
        }
    }
}

struct TableCellEditView: View {
    @State var text: String
    var onCommit: (String) -> Void
    
    var body: some View {
        TextField("", text: $text, onCommit: { onCommit(text) })
            .textFieldStyle(.roundedBorder)
    }
}
```

#### 2. MarkdownTable Model
**Location:** `Drift/Models/MarkdownTable.swift`

```swift
struct MarkdownTable: Identifiable {
    var id: UUID = UUID()
    var headers: [String]
    var rows: [[String]]
    var alignments: [Alignment]  // left, center, right
    var range: NSRange           // Position in document
    
    func toMarkdown() -> String {
        // Convert back to GFM table syntax
    }
    
    mutating func insertRow(at index: Int = -1) { }
    mutating func deleteRow(at index: Int) { }
    mutating func insertColumn(at index: Int = -1) { }
    mutating func deleteColumn(at index: Int) { }
}

enum Alignment {
    case left, center, right
}
```

#### 3. Table Parser
**Location:** `Drift/Services/MarkdownTableParser.swift`

```swift
class MarkdownTableParser {
    func parseTableAt(in textStorage: NSTextStorage, range: NSRange) -> MarkdownTable?
    func getAllTables(in textStorage: NSTextStorage) -> [MarkdownTable]
    func replaceTableContent(in textStorage: NSTextStorage, table: MarkdownTable)
}
```

#### 4. Editor Integration
**Modify:** `Drift/Views/Editor/NoteEditorView.swift`

- Add sheet trigger for table editing
- Double-click table to open TableEditorView
- Display inline table preview
- Sync changes back to markdown

### Table Markdown Format (GFM)

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

| Left | Center | Right |
|:-----|:------:|------:|
| A    |   B    |     C |
```

### Success Criteria
- ✅ Visual table editor with spreadsheet UI
- ✅ Inline cell editing
- ✅ Insert/delete rows and columns
- ✅ Preserve table alignment (left/center/right)
- ✅ Markdown sync (changes update source)
- ✅ Works with complex tables
- ✅ Zero breaking changes

---

## Phase 3B.3: Extended GFM Features (Days 2-4)

### Objective
Support additional GFM syntax: autolinks, footnotes, callouts.

### Architecture

#### 1. ExtendedGFMHighlighter Service
**Location:** `Drift/Services/ExtendedGFMHighlighter.swift`

```swift
class ExtendedGFMHighlighter {
    // Highlight autolinks: <https://example.com> or <user@example.com>
    func highlightAutolinks(_ text: String) -> [SyntaxHighlight]
    
    // Highlight footnotes: [^1] and [^1]: definition
    func highlightFootnotes(_ text: String) -> [SyntaxHighlight]
    
    // Highlight callouts: > [!NOTE], > [!WARNING], etc.
    func highlightCallouts(_ text: String) -> [SyntaxHighlight]
    
    // Combine with existing highlights
    func mergeWithMarkdownHighlights(_ existing: [SyntaxHighlight]) -> [SyntaxHighlight]
}
```

#### 2. Autolinks Support
**Syntax:**
```markdown
<https://github.com>
<user@example.com>
```

**Features:**
- Automatic clickable links
- Email detection
- Visual underline (blue)
- Drag to select support

**Color:** Cyan (#8be9fd)

#### 3. Footnotes Support
**Syntax:**
```markdown
Here is a footnote[^1].

[^1]: This is the footnote content.
     Can span multiple lines.
```

**Features:**
- Footnote reference highlighting
- Definition highlighting
- Jump to footnote on Cmd+Click
- Tooltip preview on hover

**Color:** Pink (#ff79c6) for references

#### 4. Callouts Support
**Syntax:**
```markdown
> [!NOTE]
> This is a note

> [!WARNING]
> This is a warning

> [!IMPORTANT]
> This is important
```

**Types:**
- `NOTE` - Cyan info icon
- `WARNING` - Orange warning icon
- `IMPORTANT` - Red critical icon
- `TIP` - Green checkmark icon
- `CAUTION` - Yellow alert icon

**Color-coded:** Each type has unique background + icon

#### 5. Integration with Existing System

```swift
// Modify UnifiedMarkdownHighlighter.swift
extension UnifiedMarkdownHighlighter {
    private func highlightExtendedFeatures(_ text: String) -> [SyntaxHighlight] {
        let extendedHighlighter = ExtendedGFMHighlighter()
        var highlights = [SyntaxHighlight]()
        
        highlights.append(contentsOf: extendedHighlighter.highlightAutolinks(text))
        highlights.append(contentsOf: extendedHighlighter.highlightFootnotes(text))
        highlights.append(contentsOf: extendedHighlighter.highlightCallouts(text))
        
        return highlights
    }
}
```

### Success Criteria
- ✅ Autolinks recognized and highlighted
- ✅ Footnotes with cross-references
- ✅ Callouts with color-coded types
- ✅ Visual consistency with Dracula theme
- ✅ Seamless integration with Phase 3A
- ✅ Zero breaking changes

---

## Cross-Cutting Concerns

### Undo/Redo Support
All interactive changes (checkbox toggle, table edit, etc.) must:
- Register with NSUndoManager
- Support Cmd+Z / Cmd+Shift+Z
- Update Note.content consistently
- Sync to AppState

### Performance
- Cache task list positions for quick lookup
- Lazy-load table editor (only parse tables when viewing)
- Batch NSTextStorage updates for multiple changes
- Profile on documents >100KB

### Accessibility
- VoiceOver support for checkboxes
- Keyboard navigation in table editor
- ARIA labels in exported HTML
- Color-blind friendly patterns (not just color)

### Testing Strategy

#### Unit Tests
- `TaskListInteractivityManagerTests` (12 tests)
  - Toggle state transitions
  - Position detection
  - Nested lists
  - Progress calculation

- `MarkdownTableParserTests` (10 tests)
  - Parse various table formats
  - Alignment detection
  - Cell extraction
  - Edge cases (empty cells, special chars)

- `ExtendedGFMHighlighterTests` (12 tests)
  - Autolinks parsing
  - Footnote detection
  - Callout type recognition
  - Priority handling

#### Integration Tests (15 tests)
- Interactive checkbox toggle in editor
- Table editing and markdown sync
- Extended features rendering
- Large document performance

#### UI Tests (8 tests)
- Click checkbox, verify visual update
- Open table editor, make changes
- Verify markdown reflects updates
- Test undo/redo workflow

### Code Organization

```
Drift/Services/
  ├── TaskListInteractivityManager.swift (NEW)
  ├── MarkdownTableParser.swift (NEW)
  └── ExtendedGFMHighlighter.swift (NEW)

Drift/Models/
  └── MarkdownTable.swift (NEW)

Drift/Views/Editor/
  └── TableEditorView.swift (NEW)

DriftTests/
  ├── TaskListInteractivityManagerTests.swift (NEW)
  ├── MarkdownTableParserTests.swift (NEW)
  └── ExtendedGFMHighlighterTests.swift (NEW)
```

---

## Timeline & Milestones

| Day | Phase | Tasks | Expected LOC |
|-----|-------|-------|--------------|
| 1   | 3B.1  | Design + TaskListInteractivityManager | 250 |
| 2   | 3B.1  | Editor integration + tests | 150 |
| 3   | 3B.2  | TableEditorView + TableParser | 350 |
| 4   | 3B.2  | Editor integration + tests | 200 |
| 5   | 3B.3  | ExtendedGFMHighlighter + tests | 300 |
| 5   | Tests | Integration tests + build verify | 200 |

**Total Expected Code:** 1,450 lines (services) + 350 lines (tests) = 1,800 lines

---

## Success Criteria

### Phase 3B Complete When:
- ✅ Task checkboxes clickable and toggle correctly
- ✅ Table editor provides spreadsheet UI
- ✅ Extended GFM features (autolinks, footnotes, callouts) highlighted
- ✅ All interactive features persist to Note
- ✅ Undo/redo works for all operations
- ✅ 35+ unit/integration tests passing
- ✅ Debug & Release builds succeeding
- ✅ Zero breaking changes, fully backward compatible
- ✅ Performance acceptable on 100KB+ documents
- ✅ Code committed to main branch

---

## Notes

- Leverage existing `UnifiedMarkdownHighlighter` for consistency
- Reuse `LanguageSyntaxHighlighter` patterns for new features
- Maintain bridge pattern for backward compatibility
- Use Dracula theme for visual consistency
- Cache results to avoid repeated parsing

