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
        
        // Headers: ^(#{1,6})\s+(.+)$
        applyHighlighting(pattern: "^#{1,6}\\s+.+$", text: text, storage: storage, color: colors.heading)
        
        // Bold: \*\*(.+?)\*\*|__(.+?)__
        applyHighlighting(pattern: "\\*\\*.+?\\*\\*|__.+?__", text: text, storage: storage, color: colors.bold)
        
        // Italic: \*(.+?)\*|_(.+?)_
        applyHighlighting(pattern: "\\*.+?\\*|_.+?_", text: text, storage: storage, color: colors.italic)
        
        // Strikethrough: ~~(.+?)~~
        applyHighlighting(pattern: "~~.+?~~", text: text, storage: storage, color: colors.strikethrough)
        
        // Inline code: `(.+?)`
        applyHighlighting(pattern: "`.+?`", text: text, storage: storage, color: colors.code)
        
        // Code block: ^```(?:\s*(\w+))?([\s\S]*?)^```$
        applyHighlighting(pattern: "^```[^`]*```$", text: text, storage: storage, color: colors.code)
        
        // Links: \[(.*?)\]\((.*?)\s?(?:\"(.*?)\")?\)
        applyHighlighting(pattern: "\\[.+?\\]\\(.+?\\)", text: text, storage: storage, color: colors.link)
        
        // Images: !\[(.*?)\]\((.*?)\s?(?:\"(.*?)\")?\)
        applyHighlighting(pattern: "!\\[.+?\\]\\(.+?\\)", text: text, storage: storage, color: colors.link)
        
        // Blockquote: ^>\s*(.+)$
        applyHighlighting(pattern: "^>\\s*.+$", text: text, storage: storage, color: colors.blockquote)
        
        // Unordered list: ^\s*[-+*]\s+(.+)$
        applyHighlighting(pattern: "^\\s*[-+*]\\s+.+$", text: text, storage: storage, color: colors.list)
        
        // Ordered list: ^\s*\d+\.\s+(.+)$
        applyHighlighting(pattern: "^\\s*\\d+\\.\\s+.+$", text: text, storage: storage, color: colors.list)
    }
    
    private static func applyHighlighting(pattern: String, text: String, storage: NSTextStorage, color: NSColor) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.useUnicodeWordBoundaries, .anchorsMatchLines]) else {
            return
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        for match in matches {
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
            storage.addAttributes(attributes, range: match.range)
        }
    }
}
