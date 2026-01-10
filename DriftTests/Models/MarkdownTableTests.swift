import XCTest
@testable import Drift

final class MarkdownTableTests: XCTestCase {
    var parser: MarkdownTableParser!
    
    override func setUp() {
        super.setUp()
        parser = MarkdownTableParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    // MARK: - Table Parsing Tests
    
    func testParseSimpleTable() {
        let markdown = """
        | Header 1 | Header 2 |
        | --- | --- |
        | Cell 1 | Cell 2 |
        | Cell 3 | Cell 4 |
        """
        
        let tables = parser.parseAll(in: markdown)
        XCTAssertEqual(tables.count, 1, "Should parse one table")
        XCTAssertEqual(tables[0].headers, ["Header 1", "Header 2"])
        XCTAssertEqual(tables[0].rows.count, 2)
    }
    
    func testParseTableWithAlignment() {
        let markdown = """
        | Left | Center | Right |
        | :--- | :---: | ---: |
        | L1 | C1 | R1 |
        """
        
        let tables = parser.parseAll(in: markdown)
        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables[0].alignments, [.left, .center, .right])
    }
    
    func testParseMultipleTables() {
        let markdown = """
        | H1 | H2 |
        | --- | --- |
        | C1 | C2 |
        
        | H3 | H4 |
        | --- | --- |
        | C3 | C4 |
        """
        
        let tables = parser.parseAll(in: markdown)
        XCTAssertEqual(tables.count, 2, "Should parse two tables")
    }
    
    func testParseTableWithWhitespace() {
        let markdown = """
        |  Header 1  |  Header 2  |
        |  ---  |  ---  |
        |  Cell 1  |  Cell 2  |
        """
        
        let tables = parser.parseAll(in: markdown)
        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables[0].headers, ["Header 1", "Header 2"])
    }
    
    func testParseTableWithPipes() {
        let markdown = """
        | Code | Result |
        | --- | --- |
        | `a \| b` | a \| b |
        """
        
        let tables = parser.parseAll(in: markdown)
        XCTAssertEqual(tables.count, 1)
    }
    
    func testParseInvalidTableReturnsEmpty() {
        let markdown = """
        | Header 1 | Header 2 |
        | Cell 1 | Cell 2 |
        """
        
        let tables = parser.parseAll(in: markdown)
        // Invalid because no separator row
        XCTAssertEqual(tables.count, 0)
    }
    
    func testParseTableWithVariableColumns() {
        let markdown = """
        | H1 | H2 | H3 |
        | --- | --- | --- |
        | C1 | C2 | C3 |
        | C4 | C5 |
        """
        
        let tables = parser.parseAll(in: markdown)
        XCTAssertEqual(tables.count, 1)
        // Parser should handle variable column counts gracefully
    }
    
    // MARK: - Table Row/Column Operations
    
    func testInsertRowAtEnd() {
        var table = MarkdownTable(
            headers: ["H1", "H2"],
            rows: [["C1", "C2"]],
            alignments: [.left, .left],
            range: NSRange(location: 0, length: 0)
        )
        
        table.insertRow(at: 1, with: ["New1", "New2"])
        XCTAssertEqual(table.rows.count, 2)
        XCTAssertEqual(table.rows[1], ["New1", "New2"])
    }
    
    func testInsertRowAtBeginning() {
        var table = MarkdownTable(
            headers: ["H1", "H2"],
            rows: [["C1", "C2"]],
            alignments: [.left, .left],
            range: NSRange(location: 0, length: 0)
        )
        
        table.insertRow(at: 0, with: ["New1", "New2"])
        XCTAssertEqual(table.rows.count, 2)
        XCTAssertEqual(table.rows[0], ["New1", "New2"])
    }
    
    func testDeleteRow() {
        var table = MarkdownTable(
            headers: ["H1", "H2"],
            rows: [["C1", "C2"], ["C3", "C4"], ["C5", "C6"]],
            alignments: [.left, .left],
            range: NSRange(location: 0, length: 0)
        )
        
        table.deleteRow(at: 1)
        XCTAssertEqual(table.rows.count, 2)
        XCTAssertEqual(table.rows[1], ["C5", "C6"])
    }
    
    func testInsertColumn() {
        var table = MarkdownTable(
            headers: ["H1", "H2"],
            rows: [["C1", "C2"]],
            alignments: [.left, .left],
            range: NSRange(location: 0, length: 0)
        )
        
        table.insertColumn(at: 1, with: "NewHeader", newRows: ["NewCell"])
        XCTAssertEqual(table.headers.count, 3)
        XCTAssertEqual(table.alignments.count, 3)
    }
    
    func testDeleteColumn() {
        var table = MarkdownTable(
            headers: ["H1", "H2", "H3"],
            rows: [["C1", "C2", "C3"]],
            alignments: [.left, .left, .left],
            range: NSRange(location: 0, length: 0)
        )
        
        table.deleteColumn(at: 1)
        XCTAssertEqual(table.headers.count, 2)
        XCTAssertEqual(table.headers, ["H1", "H3"])
    }
    
    // MARK: - Table Alignment Tests
    
    func testAlignmentParsing() {
        let alignments = [
            (":---", TableAlignment.left),
            ("---:", TableAlignment.right),
            (":---:", TableAlignment.center),
            ("---", TableAlignment.left)
        ]
        
        for (marker, expected) in alignments {
            if let alignment = TableAlignment(rawValue: marker) {
                XCTAssertEqual(alignment, expected)
            } else {
                XCTFail("Should parse alignment: \(marker)")
            }
        }
    }
    
    func testDefaultAlignment() {
        let markdown = """
        | H1 | H2 |
        | --- | --- |
        | C1 | C2 |
        """
        
        let tables = parser.parseAll(in: markdown)
        XCTAssertEqual(tables[0].alignments, [.left, .left])
    }
    
    // MARK: - Markdown Generation Tests
    
    func testToMarkdown() {
        let table = MarkdownTable(
            headers: ["H1", "H2"],
            rows: [["C1", "C2"], ["C3", "C4"]],
            alignments: [.left, .right],
            range: NSRange(location: 0, length: 0)
        )
        
        let markdown = table.toMarkdown()
        XCTAssertTrue(markdown.contains("| H1 | H2 |"))
        XCTAssertTrue(markdown.contains("| :--- | ---: |"))
        XCTAssertTrue(markdown.contains("| C1 | C2 |"))
        XCTAssertTrue(markdown.contains("| C3 | C4 |"))
    }
    
    func testToMarkdownWithCenteredAlignment() {
        let table = MarkdownTable(
            headers: ["H1", "H2"],
            rows: [["C1", "C2"]],
            alignments: [.center, .center],
            range: NSRange(location: 0, length: 0)
        )
        
        let markdown = table.toMarkdown()
        XCTAssertTrue(markdown.contains("| :---: | :---: |"))
    }
    
    func testRoundTripParsing() {
        let original = """
        | H1 | H2 |
        | --- | --- |
        | C1 | C2 |
        """
        
        let tables = parser.parseAll(in: original)
        let reconstructed = tables[0].toMarkdown()
        
        let reparsed = parser.parseAll(in: reconstructed)
        XCTAssertEqual(reparsed.count, 1)
        XCTAssertEqual(reparsed[0].headers, tables[0].headers)
        XCTAssertEqual(reparsed[0].rows, tables[0].rows)
    }
    
    // MARK: - Edge Cases
    
    func testTableWithEmptyCells() {
        let markdown = """
        | H1 | H2 |
        | --- | --- |
        | | C2 |
        | C1 | |
        """
        
        let tables = parser.parseAll(in: markdown)
        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables[0].rows.count, 2)
    }
    
    func testTableWithSpecialCharacters() {
        let markdown = """
        | Code | Symbol |
        | --- | --- |
        | `<>` | & |
        | `{}` | * |
        """
        
        let tables = parser.parseAll(in: markdown)
        XCTAssertEqual(tables.count, 1)
    }
}
