//
//  MarkdownTable.swift
//  Drift
//
//  Model representing a GFM table in markdown
//

import Foundation
import AppKit

// MARK: - Alignment

enum TableAlignment: String, Codable {
    case left = ":---"
    case center = ":---:"
    case right = "---:"
    
    var display: String {
        switch self {
        case .left: return "⬅️ Left"
        case .center: return "⬆️ Center"
        case .right: return "➡️ Right"
        }
    }
    
    static func fromMarkdown(_ marker: String) -> TableAlignment {
        let trimmed = marker.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix(":") && trimmed.hasSuffix(":") {
            return .center
        } else if trimmed.hasSuffix(":") {
            return .right
        } else if trimmed.hasPrefix(":") {
            return .left
        } else {
            return .left  // Default
        }
    }
    
    func toMarkdown() -> String {
        return self.rawValue
    }
}

// MARK: - Table Model

struct MarkdownTable: Identifiable, Codable {
    var id: UUID = UUID()
    var headers: [String]
    var rows: [[String]]
    var alignments: [TableAlignment]
    var range: NSRange
    
    var columnCount: Int {
        headers.count
    }
    
    var rowCount: Int {
        rows.count
    }
    
    /// Convert table back to GFM markdown
    func toMarkdown() -> String {
        var markdown = ""
        
        // Header row
        markdown += "| " + headers.joined(separator: " | ") + " |\n"
        
        // Separator row with alignment markers
        let separators = alignments.map { align in
            switch align {
            case .left: return "---"
            case .center: return "---"
            case .right: return "---"
            }
        }
        markdown += "|" + separators.joined(separator: "|") + "|\n"
        
        // Data rows
        for row in rows {
            let paddedRow = row.count >= columnCount
                ? Array(row.prefix(columnCount))
                : row + Array(repeating: "", count: columnCount - row.count)
            
            markdown += "| " + paddedRow.joined(separator: " | ") + " |\n"
        }
        
        return markdown
    }
    
    /// Create an empty table with specified dimensions
    static func empty(columns: Int, rows: Int = 2) -> MarkdownTable {
        let headers = (1...columns).map { "Header \($0)" }
        let emptyRows = (1...rows).map { _ in (1...columns).map { _ in "" } }
        let alignments = (1...columns).map { _ in TableAlignment.left }
        
        return MarkdownTable(
            headers: headers,
            rows: emptyRows,
            alignments: alignments,
            range: NSRange(location: 0, length: 0)
        )
    }
    
    /// Insert a new row at the specified index
    mutating func insertRow(at index: Int? = nil) {
        let insertAt = index ?? rows.count
        let emptyRow = Array(repeating: "", count: columnCount)
        rows.insert(emptyRow, at: min(insertAt, rows.count))
    }
    
    /// Delete row at specified index
    mutating func deleteRow(at index: Int) {
        guard index >= 0 && index < rows.count else { return }
        rows.remove(at: index)
    }
    
    /// Insert a new column at the specified index
    mutating func insertColumn(at index: Int? = nil) {
        let insertAt = index ?? columnCount
        headers.insert("Column", at: min(insertAt, columnCount))
        alignments.insert(.left, at: min(insertAt, columnCount))
        
        for i in 0..<rows.count {
            rows[i].insert("", at: min(insertAt, rows[i].count))
        }
    }
    
    /// Delete column at specified index
    mutating func deleteColumn(at index: Int) {
        guard index >= 0 && index < columnCount else { return }
        headers.remove(at: index)
        alignments.remove(at: index)
        
        for i in 0..<rows.count {
            if index < rows[i].count {
                rows[i].remove(at: index)
            }
        }
    }
    
    /// Update a cell value
    mutating func setCell(_ row: Int, _ column: Int, to value: String) {
        guard row >= 0 && row < rows.count && column >= 0 && column < columnCount else { return }
        rows[row][column] = value
    }
    
    /// Update a header
    mutating func setHeader(_ column: Int, to value: String) {
        guard column >= 0 && column < columnCount else { return }
        headers[column] = value
    }
    
    /// Update column alignment
    mutating func setAlignment(_ column: Int, to alignment: TableAlignment) {
        guard column >= 0 && column < columnCount else { return }
        alignments[column] = alignment
    }
}

// MARK: - Parser

@MainActor
class MarkdownTableParser {
    
    /// Regex for GFM table: pipe-separated cells with alignment row
    private let tablePattern = try! NSRegularExpression(
        pattern: "^\\|?(.+?)\\|(.+?)$",
        options: [.anchorsMatchLines]
    )
    
    private let alignmentPattern = try! NSRegularExpression(
        pattern: "^\\|?\\s*(:?-+:?)\\s*(\\|\\s*:?-+:?\\s*)*\\|?\\s*$",
        options: []
    )
    
    /// Parse all tables in the text storage
    /// - Parameter storage: The text storage to search
    /// - Returns: Array of MarkdownTable structures with their ranges
    func getAllTables(in storage: NSTextStorage) -> [MarkdownTable] {
        let text = storage.string
        let lines = text.components(separatedBy: .newlines)
        
        var tables: [MarkdownTable] = []
        var currentTableStart = -1
        var currentTableLines: [String] = []
        var lineOffset = 0
        
        for (index, line) in lines.enumerated() {
            // Check if this line is a table row (contains pipes)
            guard line.contains("|") else {
                // Not a table row - save current table if any
                if currentTableStart >= 0 && !currentTableLines.isEmpty {
                    if let table = parseTableLines(currentTableLines, startOffset: lineOffset - currentTableLines.count * (lines[0].count + 1)) {
                        tables.append(table)
                    }
                    currentTableStart = -1
                    currentTableLines = []
                }
                lineOffset += line.count + 1
                continue
            }
            
            // This line contains pipes
            if currentTableStart < 0 {
                currentTableStart = index
            }
            
            currentTableLines.append(line)
            lineOffset += line.count + 1
        }
        
        // Don't forget last table
        if currentTableStart >= 0 && !currentTableLines.isEmpty {
            if let table = parseTableLines(currentTableLines, startOffset: lineOffset - currentTableLines.count * (lines[0].count + 1)) {
                tables.append(table)
            }
        }
        
        return tables
    }
    
    /// Parse a table from an array of lines
    /// - Parameters:
    ///   - lines: Array of table lines (header, separator, data rows)
    ///   - startOffset: Offset in original text storage
    /// - Returns: Parsed MarkdownTable or nil if invalid
    private func parseTableLines(_ lines: [String], startOffset: Int) -> MarkdownTable? {
        guard lines.count >= 2 else { return nil }
        
        // Line 0 is header, Line 1 is separator
        let headerLine = lines[0]
        let separatorLine = lines[1]
        
        // Validate separator line
        guard isValidSeparator(separatorLine) else { return nil }
        
        // Parse header
        let headers = parseRow(headerLine)
        guard !headers.isEmpty else { return nil }
        
        // Parse alignment from separator
        let alignments = parseAlignment(separatorLine, columnCount: headers.count)
        guard alignments.count == headers.count else { return nil }
        
        // Parse data rows
        var rows: [[String]] = []
        for i in 2..<lines.count {
            let row = parseRow(lines[i])
            // Pad or truncate to match column count
            let paddedRow = row.count >= headers.count
                ? Array(row.prefix(headers.count))
                : row + Array(repeating: "", count: headers.count - row.count)
            rows.append(paddedRow)
        }
        
        let tableLength = lines.joined(separator: "\n").count
        let table = MarkdownTable(
            headers: headers,
            rows: rows,
            alignments: alignments,
            range: NSRange(location: startOffset, length: tableLength)
        )
        
        return table
    }
    
    /// Parse a single table row
    private func parseRow(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Remove leading and trailing pipes
        if trimmed.hasPrefix("|") {
            trimmed.removeFirst()
        }
        if trimmed.hasSuffix("|") {
            trimmed.removeLast()
        }
        
        // Split by pipe and trim each cell
        return trimmed.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    /// Check if a line is a valid table separator
    private func isValidSeparator(_ line: String) -> Bool {
        let result = alignmentPattern.numberOfMatches(
            in: line,
            range: NSRange(line.startIndex..<line.endIndex, in: line)
        )
        return result > 0
    }
    
    /// Parse alignment markers from separator line
    private func parseAlignment(_ line: String, columnCount: Int) -> [TableAlignment] {
        let cells = parseRow(line)
        
        return (0..<columnCount).map { index in
            guard index < cells.count else { return .left }
            return TableAlignment.fromMarkdown(cells[index])
        }
    }
    
    /// Find table at specific location in storage
    /// - Parameters:
    ///   - storage: Text storage to search
    ///   - location: Character location
    /// - Returns: MarkdownTable if found at location, otherwise nil
    func tableAt(in storage: NSTextStorage, location: Int) -> MarkdownTable? {
        let tables = getAllTables(in: storage)
        
        return tables.first { table in
            location >= table.range.location && location < (table.range.location + table.range.length)
        }
    }
    
    /// Replace table content in text storage
    /// - Parameters:
    ///   - storage: Text storage to modify
    ///   - table: Updated table
    func replaceTableContent(in storage: NSTextStorage, table: MarkdownTable) {
        let markdown = table.toMarkdown()
        let mutableString = storage.mutableString as NSMutableString
        
        mutableString.replaceCharacters(in: table.range, with: markdown)
    }
}
