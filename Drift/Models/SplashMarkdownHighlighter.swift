//
//  SplashMarkdownHighlighter.swift
//  Drift
//
//  Markdown syntax highlighting using Splash
//

import Foundation
import Splash
import AppKit

struct MarkdownHighlightRange {
    let range: NSRange
    let color: NSColor
}

class SplashMarkdownHighlighter {
    static let shared = SplashMarkdownHighlighter()
    
    private let attributedStringBuilder = AttributedStringBuilder()
    
    /// Highlight markdown text and return attributed string
    func highlight(_ markdown: String) -> NSAttributedString {
        let mutable = NSMutableAttributedString(string: markdown)
        let nsMarkdown = markdown as NSString
        
        // Color scheme (Dracula)
        let colors = MarkdownColors(
            heading: NSColor(red: 0.57, green: 0.93, blue: 0.96, alpha: 1.0),      // #8be9fd
            bold: NSColor(red: 0.97, green: 0.59, blue: 0.75, alpha: 1.0),         // #f55bcf
            italic: NSColor(red: 0.97, green: 0.59, blue: 0.75, alpha: 1.0),       // #f55bcf
            inlineCode: NSColor(red: 0.57, green: 0.93, blue: 0.96, alpha: 1.0),   // #8be9fd
            link: NSColor(red: 0.57, green: 0.93, blue: 0.96, alpha: 1.0),         // #8be9fd
            codeBlock: NSColor(red: 0.57, green: 0.93, blue: 0.96, alpha: 1.0),    // #8be9fd
            blockquote: NSColor(red: 0.51, green: 0.54, blue: 0.59, alpha: 1.0),   // #6272a4
            listMarker: NSColor(red: 0.97, green: 0.59, blue: 0.75, alpha: 1.0)    // #f55bcf
        )
        
        // Apply heading highlights
        applyHeadingHighlights(to: mutable, in: nsMarkdown, with: colors)
        
        // Apply bold highlights
        applyBoldHighlights(to: mutable, in: nsMarkdown, with: colors)
        
        // Apply italic highlights
        applyItalicHighlights(to: mutable, in: nsMarkdown, with: colors)
        
        // Apply inline code highlights
        applyInlineCodeHighlights(to: mutable, in: nsMarkdown, with: colors)
        
        // Apply link highlights
        applyLinkHighlights(to: mutable, in: nsMarkdown, with: colors)
        
        // Apply blockquote highlights
        applyBlockquoteHighlights(to: mutable, in: nsMarkdown, with: colors)
        
        // Apply list marker highlights
        applyListMarkerHighlights(to: mutable, in: nsMarkdown, with: colors)
        
        return mutable
    }
    
    // MARK: - Private Highlighting Methods
    
    private func applyHeadingHighlights(to mutable: NSMutableAttributedString, in text: NSString, with colors: MarkdownColors) {
        let pattern = "#+ "
        var searchStart = 0
        
        while searchStart < text.length {
            let range = text.range(of: pattern, options: .regularExpression, range: NSRange(location: searchStart, length: text.length - searchStart))
            if range.location == NSNotFound { break }
            
            // Find end of line
            let lineEndRange = text.range(of: "\n", options: [], range: NSRange(location: range.location, length: text.length - range.location))
            let lineEnd = lineEndRange.location == NSNotFound ? text.length : lineEndRange.location
            
            let highlightRange = NSRange(location: range.location, length: lineEnd - range.location)
            mutable.addAttribute(.foregroundColor, value: colors.heading, range: highlightRange)
            
            searchStart = lineEnd + 1
        }
    }
    
    private func applyBoldHighlights(to mutable: NSMutableAttributedString, in text: NSString, with colors: MarkdownColors) {
        applyPatternHighlight(pattern: "\\*\\*[^*]+\\*\\*", to: mutable, in: text, color: colors.bold)
        applyPatternHighlight(pattern: "__[^_]+__", to: mutable, in: text, color: colors.bold)
    }
    
    private func applyItalicHighlights(to mutable: NSMutableAttributedString, in text: NSString, with colors: MarkdownColors) {
        applyPatternHighlight(pattern: "\\*[^*]+\\*(?!\\*)", to: mutable, in: text, color: colors.italic)
        applyPatternHighlight(pattern: "_[^_]+_", to: mutable, in: text, color: colors.italic)
    }
    
    private func applyInlineCodeHighlights(to mutable: NSMutableAttributedString, in text: NSString, with colors: MarkdownColors) {
        applyPatternHighlight(pattern: "`[^`]+`", to: mutable, in: text, color: colors.inlineCode)
    }
    
    private func applyLinkHighlights(to mutable: NSMutableAttributedString, in text: NSString, with colors: MarkdownColors) {
        applyPatternHighlight(pattern: "\\[[^\\]]*\\]\\([^\\)]*\\)", to: mutable, in: text, color: colors.link)
    }
    
    private func applyBlockquoteHighlights(to mutable: NSMutableAttributedString, in text: NSString, with colors: MarkdownColors) {
        applyLineStartPatternHighlight(pattern: "> ", to: mutable, in: text, color: colors.blockquote)
    }
    
    private func applyListMarkerHighlights(to mutable: NSMutableAttributedString, in text: NSString, with colors: MarkdownColors) {
        applyLineStartPatternHighlight(pattern: "[-*+] ", to: mutable, in: text, color: colors.listMarker)
        applyLineStartPatternHighlight(pattern: "\\d+\\. ", to: mutable, in: text, color: colors.listMarker)
    }
    
    private func applyPatternHighlight(pattern: String, to mutable: NSMutableAttributedString, in text: NSString, color: NSColor) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        let matches = regex.matches(in: text as String, range: NSRange(location: 0, length: text.length))
        for match in matches {
            mutable.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }
    
    private func applyLineStartPatternHighlight(pattern: String, to mutable: NSMutableAttributedString, in text: NSString, color: NSColor) {
        let lines = text.components(separatedBy: .newlines)
        var currentLocation = 0
        
        for line in lines {
            if let regex = try? NSRegularExpression(pattern: "^\(pattern)"),
               regex.firstMatch(in: line, range: NSRange(location: 0, length: line.count)) != nil {
                mutable.addAttribute(.foregroundColor, value: color, range: NSRange(location: currentLocation, length: min(2, line.count)))
            }
            currentLocation += line.count + 1
        }
    }
}

struct MarkdownColors {
    let heading: NSColor
    let bold: NSColor
    let italic: NSColor
    let inlineCode: NSColor
    let link: NSColor
    let codeBlock: NSColor
    let blockquote: NSColor
    let listMarker: NSColor
}

// MARK: - AttributedStringBuilder (placeholder for potential Splash integration)
class AttributedStringBuilder {
    // Placeholder for custom Splash integration if needed
}
