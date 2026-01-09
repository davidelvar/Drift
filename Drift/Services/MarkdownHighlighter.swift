//
//  MarkdownHighlighter.swift
//  Drift
//
//  DEPRECATED: Use UnifiedMarkdownHighlighter instead
//  This is a compatibility bridge that delegates to UnifiedMarkdownHighlighter
//  for seamless transition while maintaining backward compatibility.
//

import Foundation
import AppKit

class MarkdownHighlighter {
    // Dracula color scheme (kept for backward compatibility)
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
    
    // Shared instance of unified highlighter
    private static let unifiedHighlighter = UnifiedMarkdownHighlighter()
    
    /// Highlight markdown text using UnifiedMarkdownHighlighter
    /// - Parameters:
    ///   - text: The markdown source text
    ///   - storage: The NSTextStorage to apply highlights to
    static func highlight(_ text: String, in storage: NSTextStorage) {
        // Delegate to UnifiedMarkdownHighlighter
        unifiedHighlighter.highlight(text, in: storage)
    }
}
