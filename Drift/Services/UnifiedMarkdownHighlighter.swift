//
//  UnifiedMarkdownHighlighter.swift
//  Drift
//
//  Unified markdown syntax highlighting using AST-based approach
//  Consolidates regex-based highlighting into single comprehensive system
//

import Foundation
import AppKit
import Markdown

// MARK: - Dracula Color Scheme (Unified)
struct UnifiedDraculaTheme {
    // Base colors
    static let background = NSColor(red: 0.1137, green: 0.1176, blue: 0.1569, alpha: 1.0) // #1D1E28
    static let foreground = NSColor(red: 0.973, green: 0.973, blue: 0.949, alpha: 1.0) // #f8f8f2
    
    // Markdown syntax colors
    static let heading = NSColor(red: 0.549, green: 0.915, blue: 0.993, alpha: 1.0)       // #8be9fd (cyan)
    static let bold = NSColor(red: 1.0, green: 0.474, blue: 0.778, alpha: 1.0)           // #ff79c6 (pink)
    static let italic = NSColor(red: 1.0, green: 0.474, blue: 0.778, alpha: 1.0)         // #ff79c6 (pink)
    static let strikethrough = NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0) // #6272a4 (gray)
    static let code = NSColor(red: 0.549, green: 0.915, blue: 0.993, alpha: 1.0)         // #8be9fd (cyan)
    static let link = NSColor(red: 0.549, green: 0.915, blue: 0.993, alpha: 1.0)         // #8be9fd (cyan)
    static let blockquote = NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)   // #6272a4 (gray)
    static let list = NSColor(red: 1.0, green: 0.474, blue: 0.778, alpha: 1.0)           // #ff79c6 (pink)
    static let table = NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)        // #50fa7b (green)
    static let taskCheckbox = NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0) // #f1fa8c (yellow)
    
    // Code syntax colors
    static let codePrimary = NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)   // #50fa7b (green)
    static let codeSecondary = NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0) // #bd93f9 (purple)
    static let codeComment = NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)   // #6272a4 (gray)
    static let codeString = NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)    // #f1fa8c (yellow)
}



// MARK: - Unified Markdown Highlighter
@MainActor
final class UnifiedMarkdownHighlighter {
    // MARK: - Properties
    private let defaultFont = NSFont.systemFont(ofSize: 13)
    private var highlightCache: [String: [SyntaxHighlight]] = [:]
    
    // MARK: - Public API
    
    /// Highlight markdown text and apply to NSTextStorage
    /// - Parameters:
    ///   - text: The markdown source text to highlight
    ///   - storage: The NSTextStorage to apply highlights to
    func highlight(_ text: String, in storage: NSTextStorage) {
        let highlights = generateHighlights(text)
        applyHighlights(highlights, to: storage)
    }
    
    /// Generate highlighting instructions without applying them
    /// - Parameter text: The markdown source text
    /// - Returns: Array of syntax highlights to apply
    func generateHighlights(_ text: String) -> [SyntaxHighlight] {
        // Check cache first
        if let cached = highlightCache[text] {
            return cached
        }
        
        var highlights: [SyntaxHighlight] = []
        
        // Priority-ordered highlighting (higher number = applied last, can override)
        // This order ensures correct precedence and prevents conflicts
        
        // 1. Code blocks (highest priority context - nothing inside should be highlighted)
        highlights.append(contentsOf: highlightCodeBlocks(text))
        
        // 2. Inline code spans (prevent content inside from being highlighted)
        highlights.append(contentsOf: highlightInlineCode(text))
        
        // 3. Headings
        highlights.append(contentsOf: highlightHeadings(text))
        
        // 4. Links and images (only the brackets and URLs)
        highlights.append(contentsOf: highlightLinks(text))
        
        // 5. Bold (must come before italic to prevent conflicts)
        highlights.append(contentsOf: highlightBold(text))
        
        // 6. Strikethrough
        highlights.append(contentsOf: highlightStrikethrough(text))
        
        // 7. Italic (single delimiters)
        highlights.append(contentsOf: highlightItalic(text))
        
        // 8. Blockquotes
        highlights.append(contentsOf: highlightBlockquotes(text))
        
        // 9. Lists (markers only)
        highlights.append(contentsOf: highlightListMarkers(text))
        
        // 10. Task lists (checkboxes)
        highlights.append(contentsOf: highlightTaskLists(text))
        
        // 11. Tables (pipes and alignment markers)
        highlights.append(contentsOf: highlightTables(text))
        
        // Sort by priority, then by range location
        highlights.sort { a, b in
            if a.priority != b.priority {
                return a.priority < b.priority
            }
            return a.range.location < b.range.location
        }
        
        // Cache the results
        highlightCache[text] = highlights
        
        return highlights
    }
    
    // MARK: - Private Highlighting Methods
    
    private func highlightCodeBlocks(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match fenced code blocks: ```language ... ```
        let pattern = "```[a-zA-Z0-9]*\\n[\\s\\S]*?```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return highlights }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            let highlight = SyntaxHighlight(
                range: match.range,
                color: UnifiedDraculaTheme.code,
                priority: 1  // Low priority - can be overridden for language detection
            )
            highlights.append(highlight)
        }
        
        return highlights
    }
    
    private func highlightInlineCode(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match inline code: `text`
        let pattern = "`[^`]+`"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return highlights }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            let highlight = SyntaxHighlight(
                range: match.range,
                color: UnifiedDraculaTheme.code,
                priority: 2
            )
            highlights.append(highlight)
        }
        
        return highlights
    }
    
    private func highlightHeadings(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match ATX headings: # Heading, ## Heading, etc.
        let pattern = "^#{1,6}\\s+.*$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return highlights
        }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            let highlight = SyntaxHighlight(
                range: match.range,
                color: UnifiedDraculaTheme.heading,
                priority: 3
            )
            highlights.append(highlight)
        }
        
        return highlights
    }
    
    private func highlightLinks(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match markdown links: [text](url) and images: ![alt](url)
        let pattern = "(!?)\\[([^\\]]+)\\](\\([^)]*\\))"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return highlights }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            // Highlight the image marker (!)
            if match.range(at: 1).length > 0 {
                highlights.append(SyntaxHighlight(
                    range: match.range(at: 1),
                    color: UnifiedDraculaTheme.link,
                    priority: 4
                ))
            }
            
            // Highlight brackets
            let linkTextRange = match.range(at: 2)
            let openBracket = NSRange(location: linkTextRange.location - 1, length: 1)
            let closeBracket = NSRange(location: linkTextRange.location + linkTextRange.length, length: 1)
            
            highlights.append(SyntaxHighlight(
                range: openBracket,
                color: UnifiedDraculaTheme.link,
                priority: 4
            ))
            highlights.append(SyntaxHighlight(
                range: closeBracket,
                color: UnifiedDraculaTheme.link,
                priority: 4
            ))
            
            // Highlight URL in parentheses
            highlights.append(SyntaxHighlight(
                range: match.range(at: 3),
                color: UnifiedDraculaTheme.link,
                priority: 4
            ))
        }
        
        return highlights
    }
    
    private func highlightBold(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match bold: **text** or __text__
        let pattern = "\\*\\*[^*]+\\*\\*|__[^_]+__"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return highlights }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            highlights.append(SyntaxHighlight(
                range: match.range,
                color: UnifiedDraculaTheme.bold,
                priority: 4
            ))
        }
        
        return highlights
    }
    
    private func highlightStrikethrough(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match strikethrough: ~~text~~
        let pattern = "~~[^~]+~~"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return highlights }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            highlights.append(SyntaxHighlight(
                range: match.range,
                color: UnifiedDraculaTheme.strikethrough,
                priority: 6
            ))
        }
        
        return highlights
    }
    
    private func highlightItalic(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match italic: _text_ (with word boundary checks)
        let pattern1 = "_[^_]+_"
        guard let regex1 = try? NSRegularExpression(pattern: pattern1) else { return highlights }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        var matches = regex1.matches(in: text, range: range)
        
        for match in matches {
            highlights.append(SyntaxHighlight(
                range: match.range,
                color: UnifiedDraculaTheme.italic,
                priority: 7
            ))
        }
        
        // Match italic: *text* (but avoid matching in **bold**)
        let pattern2 = "(?<!\\*)\\*[^*\\s][^*]*[^*\\s]\\*(?!\\*)"
        guard let regex2 = try? NSRegularExpression(pattern: pattern2) else { return highlights }
        
        matches = regex2.matches(in: text, range: range)
        for match in matches {
            highlights.append(SyntaxHighlight(
                range: match.range,
                color: UnifiedDraculaTheme.italic,
                priority: 7
            ))
        }
        
        return highlights
    }
    
    private func highlightBlockquotes(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match blockquotes: lines starting with >
        let pattern = "^>.*$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return highlights
        }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            highlights.append(SyntaxHighlight(
                range: match.range,
                color: UnifiedDraculaTheme.blockquote,
                priority: 8
            ))
        }
        
        return highlights
    }
    
    private func highlightListMarkers(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Unordered list markers: - * +
        let unorderedPattern = "^(\\s*)[-+*](\\s+)"
        guard let unorderedRegex = try? NSRegularExpression(pattern: unorderedPattern, options: [.anchorsMatchLines]) else {
            return highlights
        }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        var matches = unorderedRegex.matches(in: text, range: range)
        
        for match in matches {
            if match.numberOfRanges > 2 {
                let markerRange = NSRange(
                    location: match.range(at: 1).location + match.range(at: 1).length,
                    length: match.range(at: 2).length + 1
                )
                highlights.append(SyntaxHighlight(
                    range: markerRange,
                    color: UnifiedDraculaTheme.list,
                    priority: 9
                ))
            }
        }
        
        // Ordered list markers: 1. 2. etc
        let orderedPattern = "^(\\s*)(\\d+\\.)(\\s+)"
        guard let orderedRegex = try? NSRegularExpression(pattern: orderedPattern, options: [.anchorsMatchLines]) else {
            return highlights
        }
        
        matches = orderedRegex.matches(in: text, range: range)
        for match in matches {
            if match.numberOfRanges > 2 {
                highlights.append(SyntaxHighlight(
                    range: match.range(at: 2),
                    color: UnifiedDraculaTheme.list,
                    priority: 9
                ))
            }
        }
        
        return highlights
    }
    
    private func highlightTaskLists(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match task list checkboxes: [ ] or [x] (case-insensitive)
        let pattern = "-\\s\\[[x ]\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines]) else {
            return highlights
        }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            // Highlight the checkbox brackets
            let matchText = nsText.substring(with: match.range)
            if let bracketStart = matchText.range(of: "[") {
                let foundRange = nsText.range(of: matchText)
                guard foundRange.location != NSNotFound else { continue }
                
                let offset = foundRange.location + matchText.distance(from: matchText.startIndex, to: bracketStart.lowerBound)
                let bracketRange = NSRange(location: offset, length: 3) // "[x]" or "[ ]"
                
                highlights.append(SyntaxHighlight(
                    range: bracketRange,
                    color: UnifiedDraculaTheme.taskCheckbox,
                    priority: 10
                ))
            }
        }
        
        return highlights
    }
    
    private func highlightTables(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        
        // Match table separator lines: | --- | --- |
        let separatorPattern = "\\|\\s*[-:]+\\s*\\|"
        guard let separatorRegex = try? NSRegularExpression(pattern: separatorPattern) else {
            return highlights
        }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = separatorRegex.matches(in: text, range: range)
        
        for match in matches {
            highlights.append(SyntaxHighlight(
                range: match.range,
                color: UnifiedDraculaTheme.table,
                priority: 11
            ))
        }
        
        return highlights
    }
    
    // MARK: - Apply Highlights
    
    private func applyHighlights(_ highlights: [SyntaxHighlight], to storage: NSTextStorage) {
        let fullRange = NSRange(location: 0, length: storage.length)
        
        // Reset all attributes first
        storage.setAttributes(
            [.foregroundColor: UnifiedDraculaTheme.foreground],
            range: fullRange
        )
        
        // Apply highlights in order (respecting priority)
        for highlight in highlights {
            // Clamp range to valid bounds
            let validRange = NSRange(
                location: max(0, min(highlight.range.location, storage.length)),
                length: min(highlight.range.length, storage.length - highlight.range.location)
            )
            
            if validRange.length > 0 {
                storage.addAttributes(highlight.attributes, range: validRange)
            }
        }
    }
    
    // MARK: - Cache Management
    
    /// Clear the highlighting cache
    func clearCache() {
        highlightCache.removeAll()
    }
}
