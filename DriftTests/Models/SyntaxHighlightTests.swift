import XCTest
@testable import Drift

final class SyntaxHighlightTests: XCTestCase {
    
    func testInitialization() {
        let attributes = [NSAttributedString.Key.foregroundColor: NSColor.red]
        let highlight = SyntaxHighlight(
            range: NSRange(location: 0, length: 5),
            attributes: attributes,
            priority: 1
        )
        
        XCTAssertEqual(highlight.range.location, 0)
        XCTAssertEqual(highlight.range.length, 5)
        XCTAssertEqual(highlight.priority, 1)
    }
    
    func testDifferentPriorities() {
        let attributes = [NSAttributedString.Key.foregroundColor: NSColor.blue]
        
        let highlight1 = SyntaxHighlight(
            range: NSRange(location: 0, length: 5),
            attributes: attributes,
            priority: 1
        )
        
        let highlight2 = SyntaxHighlight(
            range: NSRange(location: 0, length: 5),
            attributes: attributes,
            priority: 10
        )
        
        XCTAssertLessThan(highlight1.priority, highlight2.priority)
    }
    
    func testDifferentRanges() {
        let attributes = [NSAttributedString.Key.foregroundColor: NSColor.green]
        
        let highlight1 = SyntaxHighlight(
            range: NSRange(location: 0, length: 5),
            attributes: attributes,
            priority: 1
        )
        
        let highlight2 = SyntaxHighlight(
            range: NSRange(location: 10, length: 5),
            attributes: attributes,
            priority: 1
        )
        
        XCTAssertNotEqual(highlight1.range, highlight2.range)
    }
    
    func testEmptyRange() {
        let highlight = SyntaxHighlight(
            range: NSRange(location: 0, length: 0),
            attributes: [:],
            priority: 1
        )
        
        XCTAssertEqual(highlight.range.length, 0)
    }
    
    func testLargeRange() {
        let highlight = SyntaxHighlight(
            range: NSRange(location: 0, length: 10000),
            attributes: [:],
            priority: 1
        )
        
        XCTAssertEqual(highlight.range.length, 10000)
    }
    
    func testMultipleAttributes() {
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: NSColor.red,
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12),
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        let highlight = SyntaxHighlight(
            range: NSRange(location: 0, length: 5),
            attributes: attributes,
            priority: 1
        )
        
        XCTAssertEqual(highlight.attributes.count, 3)
    }
    
    func testZeroPriority() {
        let highlight = SyntaxHighlight(
            range: NSRange(location: 0, length: 5),
            attributes: [:],
            priority: 0
        )
        
        XCTAssertEqual(highlight.priority, 0)
    }
    
    func testNegativePriority() {
        let highlight = SyntaxHighlight(
            range: NSRange(location: 0, length: 5),
            attributes: [:],
            priority: -1
        )
        
        XCTAssertEqual(highlight.priority, -1)
    }
}
