import XCTest
@testable import Drift

final class ExtendedGFMHighlighterTests: XCTestCase {
    var highlighter: ExtendedGFMHighlighter!
    
    override func setUp() {
        super.setUp()
        highlighter = ExtendedGFMHighlighter()
    }
    
    override func tearDown() {
        highlighter = nil
        super.tearDown()
    }
    
    // MARK: - Autolink Tests
    
    func testDetectSimpleAutolink() {
        let text = "Visit <https://example.com>"
        let highlights = highlighter.highlightAutolinks(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect autolink")
        XCTAssertTrue(highlights[0].range.location >= 0)
    }
    
    func testDetectEmailAutolink() {
        let text = "Email me at <user@example.com>"
        let highlights = highlighter.highlightAutolinks(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect email autolink")
    }
    
    func testDetectMultipleAutolinks() {
        let text = """
        Check <https://example.com> and <https://another.com>
        """
        let highlights = highlighter.highlightAutolinks(text)
        
        XCTAssertEqual(highlights.count, 2, "Should detect both autolinks")
    }
    
    func testNoAutolinkDetection() {
        let text = "This is just <text> without a URL"
        let highlights = highlighter.highlightAutolinks(text)
        
        XCTAssertTrue(highlights.isEmpty, "Should not detect non-URL text")
    }
    
    func testAutolinkWithSpecialCharacters() {
        let text = "<https://example.com/path?query=value&other=123>"
        let highlights = highlighter.highlightAutolinks(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect autolink with special characters")
    }
    
    // MARK: - Footnote Tests
    
    func testDetectFootnoteReference() {
        let text = "This is a footnote[^1] reference"
        let highlights = highlighter.highlightFootnotes(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect footnote reference")
    }
    
    func testDetectMultipleFootnotes() {
        let text = """
        First footnote[^1] and second[^2] and named[^ref]
        """
        let highlights = highlighter.highlightFootnotes(text)
        
        XCTAssertGreaterThanOrEqual(highlights.count, 3, "Should detect all footnote references")
    }
    
    func testFootnoteDefinition() {
        let text = "[^1]: This is the footnote definition"
        let highlights = highlighter.highlightFootnotes(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect footnote definition")
    }
    
    func testNoFootnoteDetection() {
        let text = "This has [regular] brackets, not footnotes"
        let highlights = highlighter.highlightFootnotes(text)
        
        XCTAssertTrue(highlights.isEmpty, "Should not detect regular brackets")
    }
    
    // MARK: - Callout Tests
    
    func testDetectNoteCallout() {
        let text = "> [!NOTE]\n> This is a note"
        let highlights = highlighter.highlightCallouts(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect NOTE callout")
    }
    
    func testDetectWarningCallout() {
        let text = "> [!WARNING]\n> Be careful"
        let highlights = highlighter.highlightCallouts(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect WARNING callout")
    }
    
    func testDetectImportantCallout() {
        let text = "> [!IMPORTANT]\n> Very important"
        let highlights = highlighter.highlightCallouts(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect IMPORTANT callout")
    }
    
    func testDetectTipCallout() {
        let text = "> [!TIP]\n> Helpful tip"
        let highlights = highlighter.highlightCallouts(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect TIP callout")
    }
    
    func testDetectCautionCallout() {
        let text = "> [!CAUTION]\n> Be cautious"
        let highlights = highlighter.highlightCallouts(text)
        
        XCTAssertFalse(highlights.isEmpty, "Should detect CAUTION callout")
    }
    
    func testCalloutTypeColors() {
        let calloutTypes: [(CalloutType, NSColor)] = [
            (.note, NSColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)),
            (.warning, NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)),
            (.important, NSColor(red: 1.0, green: 0.3, blue: 0.8, alpha: 1.0)),
            (.tip, NSColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 1.0)),
            (.caution, NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0))
        ]
        
        for (calloutType, expectedColor) in calloutTypes {
            XCTAssertNotNil(calloutType.color, "Callout type should have a color")
        }
    }
    
    func testInvalidCalloutType() {
        let text = "> [!UNKNOWN]\n> Unknown callout"
        let highlights = highlighter.highlightCallouts(text)
        
        XCTAssertTrue(highlights.isEmpty, "Should not detect invalid callout types")
    }
    
    // MARK: - Highlight Merging Tests
    
    func testMergeNonConflictingHighlights() {
        let highlights1 = [
            SyntaxHighlight(range: NSRange(location: 0, length: 5), attributes: [:], priority: 1)
        ]
        let highlights2 = [
            SyntaxHighlight(range: NSRange(location: 10, length: 5), attributes: [:], priority: 1)
        ]
        
        let merged = highlighter.mergeHighlights(highlights1, with: highlights2)
        XCTAssertEqual(merged.count, 2, "Should merge non-conflicting highlights")
    }
    
    func testMergeConflictingHighlightsByPriority() {
        let highlights1 = [
            SyntaxHighlight(range: NSRange(location: 0, length: 10), attributes: [:], priority: 1)
        ]
        let highlights2 = [
            SyntaxHighlight(range: NSRange(location: 5, length: 5), attributes: [:], priority: 2)
        ]
        
        let merged = highlighter.mergeHighlights(highlights1, with: highlights2)
        XCTAssertGreaterThan(merged.count, 0, "Should resolve conflicts by priority")
    }
    
    func testMergeEmptyHighlights() {
        let highlights1: [SyntaxHighlight] = []
        let highlights2 = [
            SyntaxHighlight(range: NSRange(location: 0, length: 5), attributes: [:], priority: 1)
        ]
        
        let merged = highlighter.mergeHighlights(highlights1, with: highlights2)
        XCTAssertEqual(merged.count, 1)
    }
    
    // MARK: - Combined Feature Tests
    
    func testCombinedAutolinksAndFootnotes() {
        let text = """
        Check <https://example.com> for more info[^1]
        [^1]: Reference here
        """
        
        let autolinks = highlighter.highlightAutolinks(text)
        let footnotes = highlighter.highlightFootnotes(text)
        
        XCTAssertGreaterThan(autolinks.count, 0)
        XCTAssertGreaterThan(footnotes.count, 0)
    }
    
    func testCombinedCalloutAndAutolink() {
        let text = """
        > [!NOTE]
        > Check <https://example.com>
        """
        
        let callouts = highlighter.highlightCallouts(text)
        let autolinks = highlighter.highlightAutolinks(text)
        
        XCTAssertGreaterThan(callouts.count, 0)
        XCTAssertGreaterThan(autolinks.count, 0)
    }
    
    // MARK: - Edge Cases
    
    func testPartialAutolinkNotDetected() {
        let text = "This <https://incomplete"
        let highlights = highlighter.highlightAutolinks(text)
        
        XCTAssertTrue(highlights.isEmpty, "Should not detect incomplete autolinks")
    }
    
    func testFootnoteWithSpecialCharacters() {
        let text = "Footnote with dash[^my-ref] and underscore[^my_ref]"
        let highlights = highlighter.highlightFootnotes(text)
        
        XCTAssertGreaterThanOrEqual(highlights.count, 2)
    }
    
    func testNestedCalloutSyntax() {
        let text = """
        > Regular quote
        > [!NOTE] This is inside a quote
        > More quote
        """
        let highlights = highlighter.highlightCallouts(text)
        
        XCTAssertGreaterThan(highlights.count, 0, "Should handle nested syntax")
    }
}
