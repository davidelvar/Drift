import XCTest
@testable import Drift

final class EditorInteractionTests: XCTestCase {
    var textStorage: NSTextStorage!
    var taskListManager: TaskListInteractivityManager!
    var tableParser: MarkdownTableParser!
    var highlighter: UnifiedMarkdownHighlighter!
    
    override func setUp() {
        super.setUp()
        textStorage = NSTextStorage()
        taskListManager = TaskListInteractivityManager()
        tableParser = MarkdownTableParser()
        highlighter = UnifiedMarkdownHighlighter()
    }
    
    override func tearDown() {
        textStorage = nil
        taskListManager = nil
        tableParser = nil
        highlighter = nil
        super.tearDown()
    }
    
    // MARK: - Task List Interaction Tests
    
    func testClickAndToggleCheckbox() {
        let initialText = "- [ ] Buy groceries"
        textStorage.setAttributedString(NSAttributedString(string: initialText))
        
        let range = NSRange(location: 0, length: textStorage.string.utf16.count)
        let toggled = taskListManager.toggleCheckboxAt(in: textStorage, range: range)
        
        XCTAssertTrue(toggled, "Should toggle checkbox")
        XCTAssertTrue(textStorage.string.contains("[x]"), "Should mark as completed")
    }
    
    func testToggleMultipleCheckboxes() {
        let initialText = """
        - [ ] Task 1
        - [ ] Task 2
        - [ ] Task 3
        """
        textStorage.setAttributedString(NSAttributedString(string: initialText))
        
        // Toggle first task
        let range1 = NSRange(location: 0, length: 20)
        let toggled1 = taskListManager.toggleCheckboxAt(in: textStorage, range: range1)
        XCTAssertTrue(toggled1)
        
        // Toggle third task
        let range3 = NSRange(location: 40, length: 60)
        let toggled3 = taskListManager.toggleCheckboxAt(in: textStorage, range: range3)
        XCTAssertTrue(toggled3)
        
        let stats = taskListManager.getTaskStatistics(in: textStorage.string)
        XCTAssertEqual(stats.completed, 2, "Should have 2 completed tasks")
    }
    
    func testTaskProgressTracking() {
        let initialText = """
        - [ ] Task 1
        - [ ] Task 2
        - [x] Task 3
        """
        textStorage.setAttributedString(NSAttributedString(string: initialText))
        
        let taskLists = taskListManager.getAllTaskLists(in: textStorage.string)
        let progress = taskLists[0].progress
        
        XCTAssertEqual(progress, 1.0 / 3.0, accuracy: 0.01)
    }
    
    // MARK: - Table Editing Integration Tests
    
    func testParseAndEditTable() {
        let tableMarkdown = """
        | Name | Age |
        | --- | --- |
        | Alice | 30 |
        | Bob | 25 |
        """
        textStorage.setAttributedString(NSAttributedString(string: tableMarkdown))
        
        let tables = tableParser.parseAll(in: textStorage.string)
        XCTAssertEqual(tables.count, 1)
        
        var table = tables[0]
        table.insertRow(at: 2, with: ["Charlie", "35"])
        
        XCTAssertEqual(table.rows.count, 3)
        XCTAssertEqual(table.rows[2], ["Charlie", "35"])
    }
    
    func testTableRoundTrip() {
        let originalTable = """
        | H1 | H2 | H3 |
        | :--- | :---: | ---: |
        | C1 | C2 | C3 |
        | C4 | C5 | C6 |
        """
        
        let tables = tableParser.parseAll(in: originalTable)
        let markdown = tables[0].toMarkdown()
        
        let reparsed = tableParser.parseAll(in: markdown)
        XCTAssertEqual(reparsed[0].headers, tables[0].headers)
        XCTAssertEqual(reparsed[0].rows, tables[0].rows)
    }
    
    func testMultipleTableEditing() {
        let content = """
        # Document
        
        | T1H1 | T1H2 |
        | --- | --- |
        | T1C1 | T1C2 |
        
        Some text
        
        | T2H1 | T2H2 |
        | --- | --- |
        | T2C1 | T2C2 |
        """
        
        let tables = tableParser.parseAll(in: content)
        XCTAssertEqual(tables.count, 2)
    }
    
    // MARK: - Combined Interaction Tests
    
    func testTasksAndTablesInSameDocument() {
        let content = """
        # Todo with Data
        
        - [ ] Task 1
        - [x] Task 2
        
        | Item | Status |
        | --- | --- |
        | Item A | Done |
        | Item B | Todo |
        
        - [ ] Task 3
        """
        
        let taskLists = taskListManager.getAllTaskLists(in: content)
        let tables = tableParser.parseAll(in: content)
        let highlights = highlighter.highlight(content)
        
        XCTAssertGreaterThan(taskLists.count, 0)
        XCTAssertGreaterThan(tables.count, 0)
        XCTAssertGreaterThan(highlights.count, 0)
    }
    
    // MARK: - Highlighting Integration Tests
    
    func testHighlightTaskLists() {
        let content = """
        - [ ] Task 1
        - [x] Task 2
        """
        
        let highlights = highlighter.highlight(content)
        // Task lists should be highlighted
        XCTAssertFalse(highlights.isEmpty)
    }
    
    func testHighlightTables() {
        let content = """
        | H1 | H2 |
        | --- | --- |
        | C1 | C2 |
        """
        
        let highlights = highlighter.highlight(content)
        XCTAssertFalse(highlights.isEmpty)
    }
    
    func testHighlightComplexDocument() {
        let content = """
        # Document
        
        **Bold** and *italic* text with `code`
        
        - [ ] Task
        
        | H1 | H2 |
        | --- | --- |
        | C1 | C2 |
        
        > [!NOTE]
        > Note text
        
        <https://example.com>
        """
        
        let highlights = highlighter.highlight(content)
        XCTAssertGreaterThan(highlights.count, 0, "Complex document should have highlights")
    }
    
    // MARK: - State Consistency Tests
    
    func testStateAfterMultipleEdits() {
        let initialText = "- [ ] Task"
        textStorage.setAttributedString(NSAttributedString(string: initialText))
        
        let range = NSRange(location: 0, length: textStorage.string.utf16.count)
        
        // Toggle on
        taskListManager.toggleCheckboxAt(in: textStorage, range: range)
        var stats = taskListManager.getTaskStatistics(in: textStorage.string)
        XCTAssertEqual(stats.completed, 1)
        
        // Toggle off
        taskListManager.toggleCheckboxAt(in: textStorage, range: range)
        stats = taskListManager.getTaskStatistics(in: textStorage.string)
        XCTAssertEqual(stats.completed, 0)
    }
    
    func testPerformanceWithLargeDocument() {
        var content = ""
        
        // Create 50 tasks
        for i in 0..<50 {
            content += "- [ ] Task \(i)\n"
        }
        
        // Create 10 tables
        for _ in 0..<10 {
            content += """
            | H1 | H2 |
            | --- | --- |
            | C1 | C2 |
            
            """
        }
        
        let start = Date()
        
        let taskLists = taskListManager.getAllTaskLists(in: content)
        let tables = tableParser.parseAll(in: content)
        let highlights = highlighter.highlight(content)
        
        let elapsed = Date().timeIntervalSince(start)
        
        XCTAssertGreaterThan(taskLists.count, 0)
        XCTAssertGreaterThan(tables.count, 0)
        XCTAssertGreaterThan(highlights.count, 0)
        XCTAssertLessThan(elapsed, 2.0, "Large document processing should be fast")
    }
    
    // MARK: - Edge Case Interactions
    
    func testEmptyDocumentOperations() {
        textStorage.setAttributedString(NSAttributedString(string: ""))
        
        let taskLists = taskListManager.getAllTaskLists(in: textStorage.string)
        let tables = tableParser.parseAll(in: textStorage.string)
        let highlights = highlighter.highlight(textStorage.string)
        
        XCTAssertEqual(taskLists.count, 0)
        XCTAssertEqual(tables.count, 0)
        XCTAssertEqual(highlights.count, 0)
    }
    
    func testMalformedContent() {
        let content = """
        - [ Task without closing bracket
        | Table | without
        Separator
        """
        
        let taskLists = taskListManager.getAllTaskLists(in: content)
        let tables = tableParser.parseAll(in: content)
        
        // Should handle gracefully
        XCTAssertNotNil(taskLists)
        XCTAssertNotNil(tables)
    }
}
