//
//  String+Extensions.swift
//  Drift
//
//  String utilities and extensions
//

import Foundation

extension String {
    /// Extracts the first line as a potential title
    var firstLine: String {
        components(separatedBy: .newlines).first ?? self
    }
    
    /// Returns word count
    var wordCount: Int {
        let words = self.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    /// Returns character count (excluding whitespace)
    var characterCountExcludingWhitespace: Int {
        filter { !$0.isWhitespace }.count
    }
    
    /// Strips Markdown formatting for preview
    var strippedMarkdown: String {
        var result = self
        
        // Remove headers
        result = result.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
        
        // Remove bold/italic
        result = result.replacingOccurrences(of: #"\*{1,2}([^*]+)\*{1,2}"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"_{1,2}([^_]+)_{1,2}"#, with: "$1", options: .regularExpression)
        
        // Remove links
        result = result.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        
        // Remove code blocks
        result = result.replacingOccurrences(of: #"`{1,3}[^`]+`{1,3}"#, with: "", options: .regularExpression)
        
        // Remove extra whitespace
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Truncates string to specified length with ellipsis
    func truncated(to length: Int) -> String {
        if count <= length {
            return self
        }
        return String(prefix(length - 3)) + "..."
    }
    
    /// Highlights search term in string (returns attributed string components)
    func highlightRanges(of searchTerm: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStartIndex = startIndex
        
        while searchStartIndex < endIndex,
              let range = range(of: searchTerm, options: .caseInsensitive, range: searchStartIndex..<endIndex) {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        
        return ranges
    }
}
