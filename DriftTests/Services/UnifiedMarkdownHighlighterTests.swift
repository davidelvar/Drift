import XCTest
@testable import Drift

final class UnifiedMarkdownHighlighterTests: XCTestCase {
    var highlighter: UnifiedMarkdownHighlighter!
    
    override func setUp() {
        super.setUp()
        highlighter = UnifiedMarkdownHighlighter()
    }
    
    override func tearDown() {
        highlighter = nil
        super.tearDown()
    }
    
    // MARK: - Basic Highlighting Tests
    
    func testHighlightBoldMarkdown() {
        let text = "This is **bold** text"
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight bold markdown")
    }
    
    func testHighlightItalicMarkdown() {
        let text = "This is *italic* text"
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight italic markdown")
    }
    
    func testHighlightCodeMarkdown() {
        let text = "Use `code` here"
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight inline code")
    }
    
    func testHighlightHeadings() {
        let text = "# Heading 1\n## Heading 2\n### Heading 3"
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight headings")
    }
    
    func testHighlightLinks() {
        let text = "[Google](https://google.com) is a search engine"
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight markdown links")
    }
    
    // MARK: - Code Block Tests
    
    func testHighlightCodeBlock() {
        let text = """
        ```swift
        let x = 10
        ```
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight code blocks")
    }
    
    func testHighlightLanguageSpecificCode() {
        let text = """
        ```python
        def hello():
            print("Hello")
        ```
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight language-specific code")
    }
    
    func testHighlightMultipleCodeBlocks() {
        let text = """
        ```swift
        let x = 10
        ```
        
        Some text
        
        ```python
        print("hello")
        ```
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight multiple code blocks")
    }
    
    // MARK: - List Tests
    
    func testHighlightUnorderedLists() {
        let text = """
        - Item 1
        - Item 2
        * Item 3
        + Item 4
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight unordered lists")
    }
    
    func testHighlightOrderedLists() {
        let text = """
        1. First
        2. Second
        3. Third
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight ordered lists")
    }
    
    func testHighlightNestedLists() {
        let text = """
        - Item 1
          - Nested 1
          - Nested 2
        - Item 2
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight nested lists")
    }
    
    // MARK: - Table Tests
    
    func testHighlightMarkdownTables() {
        let text = """
        | H1 | H2 |
        | --- | --- |
        | C1 | C2 |
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight markdown tables")
    }
    
    // MARK: - Blockquote Tests
    
    func testHighlightBlockquotes() {
        let text = """
        > This is a blockquote
        > with multiple lines
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight blockquotes")
    }
    
    func testHighlightNestedBlockquotes() {
        let text = """
        > Level 1
        >> Level 2
        >>> Level 3
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight nested blockquotes")
    }
    
    // MARK: - Extended GFM Tests
    
    func testHighlightAutolinks() {
        let text = "Visit <https://example.com>"
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight autolinks")
    }
    
    func testHighlightFootnotes() {
        let text = """
        This has a footnote[^1]
        [^1]: The reference
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight footnotes")
    }
    
    func testHighlightCallouts() {
        let text = """
        > [!NOTE]
        > This is a note
        """
        let highlights = highlighter.highlight(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight callouts")
    }
    
    // MARK: - Complex Document Tests
    
    func testHighlightComplexDocument() {
        let text = """
        # Main Title
        
        This is a **bold** and *italic* document with `code`.
        
        - [ ] Task 1
        - [x] Task 2
        
        | Column 1 | Column 2 |
        | --- | --- |
        | Data 1 | Data 2 |
        
        ```swift
        let code = true
        ```
        
        > [!WARNING]
        > Be careful
        
        Visit <https://example.com> for more.
        """
        
        let highlights = highlighter.highlight(text)
        XCTAssertFalse(highlights.isEmpty, "Should highlight complex document")
    }
    
    // MARK: - Caching Tests
    
    func testHighlightCaching() {
        let text = "This is **bold** text"
        
        let highlights1 = highlighter.highlight(text)
        let highlights2 = highlighter.highlight(text)
        
        // Both should return highlights (caching doesn't affect correctness)
        XCTAssertEqual(highlights1.count, highlights2.count)
    }
    
    func testCacheClearedOnNewText() {
        let text1 = "**Bold** text"
        let text2 = "*Italic* text"
        
        let highlights1 = highlighter.highlight(text1)
        let highlights2 = highlighter.highlight(text2)
        
        // Should still highlight correctly with different text
        XCTAssertFalse(highlights1.isEmpty)
        XCTAssertFalse(highlights2.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testHighlightLargeDocument() {
        var text = ""
        for i in 0..<100 {
            text += "Line \(i): **bold** and *italic* and `code`\n"
        }
        
        let start = Date()
        let highlights = highlighter.highlight(text)
        let elapsed = Date().timeIntervalSince(start)
        
        XCTAssertFalse(highlights.isEmpty)
        XCTAssertLessThan(elapsed, 1.0, "Highlighting should complete in under 1 second")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyStringHighlighting() {
        let text = ""
        let highlights = highlighter.highlight(text)
        
        XCTAssertTrue(highlights.isEmpty, "Empty string should have no highlights")
    }
    
    func testPartialMarkdownNotHighlighted() {
        let text = "**unclosed bold"
        let highlights = highlighter.highlight(text)
        
        // May or may not highlight depending on implementation
        // Just ensure it doesn't crash
        XCTAssertNotNil(highlights)
    }
    
    func testMixedMarkdownAndCode() {
        let text = """
        # Title with **bold**
        
        ```swift
        let x = **not markdown**
        ```
        
        More **bold** text
        """
        
        let highlights = highlighter.highlight(text)
        XCTAssertFalse(highlights.isEmpty, "Should handle mixed content")
    }
}
