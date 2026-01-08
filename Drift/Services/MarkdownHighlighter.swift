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
        
        // Headers: # ## ### etc.
        applyHighlighting(pattern: "^#+\\s.*$", text: text, storage: storage, color: colors.heading, isRegex: true)
        
        // Bold: **text** or __text__
        applyHighlighting(pattern: "\\*\\*[^*]+\\*\\*|__[^_]+__", text: text, storage: storage, color: colors.bold, isRegex: true)
        
        // Italic: *text* or _text_ (but not inside bold)
        applyHighlighting(pattern: "(?<!\\*|_)[*_][^*_]+[*_](?!\\*|_)", text: text, storage: storage, color: colors.italic, isRegex: true)
        
        // Inline code: `text`
        applyHighlighting(pattern: "`[^`]+`", text: text, storage: storage, color: colors.code, isRegex: true)
        
        // Code blocks: ```text```
        applyHighlighting(pattern: "```[\\s\\S]*?```", text: text, storage: storage, color: colors.code, isRegex: true)
        
        // Links: [text](url)
        applyHighlighting(pattern: "\\[[^\\]]+\\]\\([^)]+\\)", text: text, storage: storage, color: colors.link, isRegex: true)
        
        // Blockquotes: > text
        applyHighlighting(pattern: "^>\\s.*$", text: text, storage: storage, color: colors.blockquote, isRegex: true)
        
        // Lists: - item, * item, 1. item
        applyHighlighting(pattern: "^[\\s]*[-*+]\\s|^[\\s]*\\d+\\.\\s", text: text, storage: storage, color: colors.list, isRegex: true)
    }
    
    private static func applyHighlighting(pattern: String, text: String, storage: NSTextStorage, color: NSColor, isRegex: Bool) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: isRegex ? [.useUnicodeWordBoundaries, .anchorsMatchLines] : []) else {
            return
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        for match in matches {
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
            storage.addAttributes(attributes, range: match.range)
        }
    }
}
