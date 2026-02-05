import XCTest
@testable import Drift

final class SyntaxHighlightingTests: XCTestCase {
    
    // MARK: - Code Block Range Detection
    
    func testSimpleCodeBlockRangeDetection() {
        let text = """
        Some text
        ```
        let x = 42
        ```
        More text
        """
        
        let ranges = getCodeBlockRanges(text)
        XCTAssertEqual(ranges.count, 1, "Should detect exactly one code block")
        
        // The range should include the opening and closing backticks
        let range = ranges[0]
        XCTAssertGreaterThan(range.length, 0, "Code block range should have positive length")
    }
    
    func testMultipleCodeBlocks() {
        let text = """
        ```swift
        let x = 42
        ```
        
        Some text in between
        
        ```python
        x = 42
        ```
        """
        
        let ranges = getCodeBlockRanges(text)
        XCTAssertEqual(ranges.count, 2, "Should detect two code blocks")
    }
    
    func testCodeBlockWithLanguage() {
        let text = """
        ```python
        def hello():
            print("world")
        ```
        """
        
        let ranges = getCodeBlockRanges(text)
        XCTAssertEqual(ranges.count, 1, "Should detect code block with language identifier")
    }
    
    func testNoCodeBlocks() {
        let text = "Just some regular text without any code blocks"
        
        let ranges = getCodeBlockRanges(text)
        XCTAssertEqual(ranges.count, 0, "Should detect no code blocks")
    }
    
    func testUnmatchedOpeningBackticks() {
        let text = """
        ```python
        def hello():
            print("world")
        
        (no closing backticks)
        """
        
        let ranges = getCodeBlockRanges(text)
        XCTAssertEqual(ranges.count, 0, "Should not detect incomplete code block")
    }
    
    // MARK: - Code Block Content Range
    
    func testCodeBlockRangeIncludes Opening() {
        let text = """
        ```
        code here
        ```
        """
        
        let ranges = getCodeBlockRanges(text)
        XCTAssertEqual(ranges.count, 1)
        
        let range = ranges[0]
        let fullText = (text as NSString).substring(with: range)
        XCTAssertTrue(fullText.starts(with: "```"), "Range should include opening backticks")
    }
    
    func testCodeBlockRangeIncludesClosing() {
        let text = """
        ```
        code here
        ```
        """
        
        let ranges = getCodeBlockRanges(text)
        let range = ranges[0]
        let fullText = (text as NSString).substring(with: range)
        XCTAssertTrue(fullText.hasSuffix("```"), "Range should include closing backticks")
    }
    
    // MARK: - Position Tracking
    
    func testCodeBlockRangePositionsCorrectly() {
        let text = """
        Line 1
        ```
        code
        ```
        Line 5
        """
        
        let ranges = getCodeBlockRanges(text)
        XCTAssertEqual(ranges.count, 1)
        
        let range = ranges[0]
        // Should start after "Line 1\n" (7 characters)
        XCTAssertGreaterThanOrEqual(range.location, 7, "Code block should start after first line")
        
        // The content should contain the triple backticks
        let content = (text as NSString).substring(with: range)
        XCTAssertTrue(content.contains("```"))
        XCTAssertTrue(content.contains("code"))
    }
    
    func testCodeBlockRangeWithUnderscores() {
        let text = """
        ```python
        while game_is_running:
            process_input()
            update_state(delta_time)
        ```
        """
        
        let ranges = getCodeBlockRanges(text)
        XCTAssertEqual(ranges.count, 1, "Should detect code block with underscores")
        
        // Verify the range includes all the underscores
        let range = ranges[0]
        let content = (text as NSString).substring(with: range)
        XCTAssertTrue(content.contains("game_is_running"))
        XCTAssertTrue(content.contains("delta_time"))
    }
    
    // MARK: - Helper
    
    /// Extract code block ranges using the same logic as the coordinator
    private func getCodeBlockRanges(_ string: String) -> [NSRange] {
        let lines = string.components(separatedBy: .newlines)
        var codeBlockRanges: [NSRange] = []
        var inCodeBlock = false
        var blockStartPosition = 0
        var currentPosition = 0
        
        for line in lines {
            if line.starts(with: "```") {
                if inCodeBlock {
                    // Closing fence
                    let blockEnd = currentPosition + line.count
                    codeBlockRanges.append(NSRange(location: blockStartPosition, length: blockEnd - blockStartPosition))
                    inCodeBlock = false
                } else {
                    // Opening fence
                    blockStartPosition = currentPosition
                    inCodeBlock = true
                }
            }
            
            currentPosition += line.count + 1
        }
        
        return codeBlockRanges
    }
}
