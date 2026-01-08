//
//  MarkdownHighlighter.swift
//  Drift
//
//  Markdown syntax highlighting for NSTextView
//

import Foundation
import AppKit

class MarkdownHighlighter {
    // Dracula color scheme
    static let colors = (
        heading: NSColor(red: 0.55, green: 0.93, blue: 0.96, alpha: 1.0),      // #8be9fd (cyan)
        bold: NSColor(red: 0.97, green: 0.59, blue: 0.75, alpha: 1.0),         // #f55bcf (magenta)
        italic: NSColor(red: 0.97, green: 0.59, blue: 0.75, alpha: 1.0),       // #f55bcf (magenta)
        strikethrough: NSColor(red: 0.51, green: 0.54, blue: 0.59, alpha: 1.0), // #6272a4 (gray)
        code: NSColor(red: 0.55, green: 0.93, blue: 0.96, alpha: 1.0),         // #8be9fd (cyan)
        link: NSColor(red: 0.55, green: 0.93, blue: 0.96, alpha: 1.0),         // #8be9fd (cyan)
        blockquote: NSColor(red: 0.51, green: 0.54, blue: 0.59, alpha: 1.0),   // #6272a4 (gray)
        list: NSColor(red: 0.97, green: 0.59, blue: 0.75, alpha: 1.0),         // #f55bcf (magenta)
        text: NSColor(red: 0.973, green: 0.973, blue: 0.949, alpha: 1.0)       // #f8f8f2 (white)
    )
    
    static func highlight(_ text: String, in storage: NSTextStorage) {
        let range = NSRange(text.startIndex..., in: text)
        
        // Reset all attributes first
        storage.setAttributes([.foregroundColor: colors.text], range: range)
        
        // Apply highlighting in priority order to handle nesting properly
        // 1. Code blocks first (highest priority - nothing inside should be highlighted)
        highlightCodeBlocks(text: text, storage: storage)
        
        // 2. Inline code (prevent highlighting inside code spans)
        applyHighlighting(pattern: "`[^`]+`", text: text, storage: storage, color: colors.code)
        
        // 3. Links and images
        applyHighlighting(pattern: "!?\\[[^\\]]*\\]\\([^)]*\\)", text: text, storage: storage, color: colors.link)
        
        // 4. List markers only (not the entire line content)
        highlightListMarkers(text: text, storage: storage)
        
        // 5. Bold (must come before italic to prevent conflicts)
        applyHighlighting(pattern: "\\*\\*[^*]+\\*\\*|__[^_]+__", text: text, storage: storage, color: colors.bold)
        
        // 6. Strikethrough
        applyHighlighting(pattern: "~~[^~]+~~", text: text, storage: storage, color: colors.strikethrough)
        
        // 7. Italic (single delimiters, but be careful with asterisks)
        applyHighlighting(pattern: "_[^_]+_", text: text, storage: storage, color: colors.italic)
        // For *text*, require word boundaries to avoid false positives
        applyHighlighting(pattern: "\\*[^*\\s][^*]*[^*\\s]\\*", text: text, storage: storage, color: colors.italic)
        
        // 8. Blockquotes
        applyHighlighting(pattern: "^>.*$", text: text, storage: storage, color: colors.blockquote)
        
        // 9. Headers
        applyHighlighting(pattern: "^#{1,6}\\s+.*$", text: text, storage: storage, color: colors.heading)
    }
    
    private static func highlightListMarkers(text: String, storage: NSTextStorage) {
        // Highlight only the list marker (- + * or number.), not the entire line
        // Unordered lists: highlight "  - " or "  * " or "  + "
        let unorderedPattern = "^(\\s*)[-+*](\\s+)"
        // Ordered lists: highlight "  1. " etc
        let orderedPattern = "^(\\s*)(\\d+\\.)(\\s+)"
        
        guard let unorderedRegex = try? NSRegularExpression(pattern: unorderedPattern, options: [.anchorsMatchLines]) else {
            return
        }
        guard let orderedRegex = try? NSRegularExpression(pattern: orderedPattern, options: [.anchorsMatchLines]) else {
            return
        }
        
        let nsText = text as NSString
        let textRange = NSRange(location: 0, length: nsText.length)
        
        // Highlight unordered list markers
        let unorderedMatches = unorderedRegex.matches(in: text, options: [], range: textRange)
        for match in unorderedMatches {
            // Highlight the marker character and following space (groups 1 and 2)
            if match.numberOfRanges > 2 {
                let markerRange = NSRange(location: match.range(at: 1).location + match.range(at: 1).length,
                                         length: match.range(at: 2).length + 1) // +1 for the marker char
                let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: colors.list]
                storage.addAttributes(attributes, range: markerRange)
            }
        }
        
        // Highlight ordered list markers
        let orderedMatches = orderedRegex.matches(in: text, options: [], range: textRange)
        for match in orderedMatches {
            // Highlight the number and dot (group 2)
            if match.numberOfRanges > 2 {
                let markerRange = match.range(at: 2)
                let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: colors.list]
                storage.addAttributes(attributes, range: markerRange)
            }
        }
    }
    
    private static func highlightCodeBlocks(text: String, storage: NSTextStorage) {
        // Match code blocks: triple backticks with optional language identifier
        // Pattern matches: ``` followed by optional language name, any content, then ```
        let pattern = "```[a-zA-Z0-9]*\\n[\\s\\S]*?```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        for match in matches {
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: colors.code]
            storage.addAttributes(attributes, range: match.range)
        }
    }
    
    private static func applyHighlighting(pattern: String, text: String, storage: NSTextStorage, color: NSColor) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        for match in matches {
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
            storage.addAttributes(attributes, range: match.range)
        }
    }
}
