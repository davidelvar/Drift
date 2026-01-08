//
//  MarkdownSyntaxHighlighter.swift
//  Drift
//
//  Markdown syntax highlighting using swift-markdown AST parsing
//

import Foundation
import AppKit
import Markdown

/// Maps markdown elements to syntax highlighting attributes
struct MarkdownSyntaxHighlighter {
    
    /// Represents a range of text with an associated color/style
    struct HighlightRange {
        let range: NSRange
        let color: NSColor
        let isBold: Bool
    }
    
    // MARK: - Dracula Color Scheme
    
    static let draculaColors = (
        text: NSColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0),        // #f8f8f2
        heading: NSColor(red: 0.97, green: 0.59, blue: 0.75, alpha: 1.0),     // #f55bcf (magenta)
        bold: NSColor(red: 0.97, green: 0.59, blue: 0.75, alpha: 1.0),        // #f55bcf (magenta)
        italic: NSColor(red: 0.94, green: 0.80, blue: 0.55, alpha: 1.0),      // #f1d656 (yellow)
        code: NSColor(red: 0.57, green: 0.93, blue: 0.96, alpha: 1.0),        // #8be9fd (cyan)
        link: NSColor(red: 0.57, green: 0.93, blue: 0.96, alpha: 1.0),        // #8be9fd (cyan)
        blockquote: NSColor(red: 0.51, green: 0.54, blue: 0.59, alpha: 1.0),  // #6272a4 (comment)
        strikethrough: NSColor(red: 0.51, green: 0.54, blue: 0.59, alpha: 1.0) // #6272a4
    )
    
    /// Parse markdown and extract syntax highlighting ranges
    /// - Parameter text: The markdown text to highlight
    /// - Returns: Array of highlight ranges with colors
    static func highlight(text: String) -> [HighlightRange] {
        var highlights: [HighlightRange] = []
        
        // Parse the markdown document
        let document = Document(parsing: text)
        
        // Walk the AST and collect highlighting information
        walkDocument(document, text: text, highlights: &highlights)
        
        return highlights
    }
    
    /// Recursively walk the markdown AST and collect highlighting ranges
    private static func walkDocument(_ block: BlockContainer, text: String, highlights: inout [HighlightRange]) {
        for child in block.children {
            switch child {
            case let heading as Heading:
                highlightHeading(heading, text: text, highlights: &highlights)
            case let paragraph as Paragraph:
                highlightParagraph(paragraph, text: text, highlights: &highlights)
            case let codeBlock as CodeBlock:
                highlightCodeBlock(codeBlock, text: text, highlights: &highlights)
            case let blockQuote as BlockQuote:
                highlightBlockQuote(blockQuote, text: text, highlights: &highlights)
            case let list as UnorderedList:
                highlightList(list, text: text, highlights: &highlights)
            case let list as OrderedList:
                highlightList(list, text: text, highlights: &highlights)
            default:
                break
            }
        }
    }
    
    /// Highlight heading elements
    private static func highlightHeading(_ heading: Heading, text: String, highlights: inout [HighlightRange]) {
        // Find the heading marker (#, ##, etc.)
        let markerCount = heading.level
        let markerLength = markerCount + 1 // e.g., "# " is 2 characters
        
        // Search for the heading in the text
        if let range = findElementRange(in: text, startsWith: String(repeating: "#", count: markerCount)) {
            highlights.append(HighlightRange(range: range, color: draculaColors.heading, isBold: true))
        }
        
        // Highlight inline elements within heading
        for inline in heading.children {
            highlightInlineElement(inline, text: text, highlights: &highlights)
        }
    }
    
    /// Highlight paragraph and its inline elements
    private static func highlightParagraph(_ paragraph: Paragraph, text: String, highlights: inout [HighlightRange]) {
        for inline in paragraph.children {
            highlightInlineElement(inline, text: text, highlights: &highlights)
        }
    }
    
    /// Highlight inline elements (bold, italic, code, links, etc.)
    private static func highlightInlineElement(_ inline: Markup, text: String, highlights: inout [HighlightRange]) {
        switch inline {
        case let strong as Strong:
            // Bold text
            if let range = findElementRange(in: text, content: strongPlainText(strong)) {
                highlights.append(HighlightRange(range: range, color: draculaColors.bold, isBold: true))
            }
            // Also highlight nested elements
            for child in strong.children {
                highlightInlineElement(child, text: text, highlights: &highlights)
            }
            
        case let emphasis as Emphasis:
            // Italic text
            if let range = findElementRange(in: text, content: emphasisPlainText(emphasis)) {
                highlights.append(HighlightRange(range: range, color: draculaColors.italic, isBold: false))
            }
            // Also highlight nested elements
            for child in emphasis.children {
                highlightInlineElement(child, text: text, highlights: &highlights)
            }
            
        case let code as InlineCode:
            // Inline code
            if let range = findElementRange(in: text, content: code.code) {
                highlights.append(HighlightRange(range: range, color: draculaColors.code, isBold: false))
            }
            
        case let link as Link:
            // Link text
            let plainText = linkPlainText(link)
            if let range = findElementRange(in: text, content: plainText) {
                highlights.append(HighlightRange(range: range, color: draculaColors.link, isBold: false))
            }
            // Highlight nested inline elements
            for child in link.children {
                highlightInlineElement(child, text: text, highlights: &highlights)
            }
            
        case let strikethrough as Strikethrough:
            // Strikethrough text
            if let range = findElementRange(in: text, content: strikethroughPlainText(strikethrough)) {
                highlights.append(HighlightRange(range: range, color: draculaColors.strikethrough, isBold: false))
            }
            
        default:
            break
        }
    }
    
    /// Highlight code blocks
    private static func highlightCodeBlock(_ codeBlock: CodeBlock, text: String, highlights: inout [HighlightRange]) {
        if let range = findElementRange(in: text, startsWith: "```") {
            highlights.append(HighlightRange(range: range, color: draculaColors.code, isBold: false))
        }
    }
    
    /// Highlight block quotes
    private static func highlightBlockQuote(_ blockQuote: BlockQuote, text: String, highlights: inout [HighlightRange]) {
        if let range = findElementRange(in: text, startsWith: ">") {
            highlights.append(HighlightRange(range: range, color: draculaColors.blockquote, isBold: false))
        }
    }
    
    /// Highlight list items
    private static func highlightList(_ list: Markup, text: String, highlights: inout [HighlightRange]) {
        // Mark list markers
        let markers = ["- ", "* ", "+ ", "1. ", "2. "]
        for marker in markers {
            if let range = findElementRange(in: text, startsWith: marker) {
                highlights.append(HighlightRange(range: range, color: draculaColors.blockquote, isBold: false))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Extract plain text from Strong element
    private static func strongPlainText(_ strong: Strong) -> String {
        strong.children.compactMap { child -> String? in
            if let text = child as? Text {
                return text.string
            }
            return nil
        }.joined()
    }
    
    /// Extract plain text from Emphasis element
    private static func emphasisPlainText(_ emphasis: Emphasis) -> String {
        emphasis.children.compactMap { child -> String? in
            if let text = child as? Text {
                return text.string
            }
            return nil
        }.joined()
    }
    
    /// Extract plain text from Link element
    private static func linkPlainText(_ link: Link) -> String {
        link.children.compactMap { child -> String? in
            if let text = child as? Text {
                return text.string
            }
            return nil
        }.joined()
    }
    
    /// Extract plain text from Strikethrough element
    private static func strikethroughPlainText(_ strikethrough: Strikethrough) -> String {
        strikethrough.children.compactMap { child -> String? in
            if let text = child as? Text {
                return text.string
            }
            return nil
        }.joined()
    }
    
    /// Find a range in text by searching for content
    private static func findElementRange(in text: String, content: String) -> NSRange? {
        if let range = text.range(of: content) {
            return NSRange(range, in: text)
        }
        return nil
    }
    
    /// Find a range in text by searching for prefix
    private static func findElementRange(in text: String, startsWith prefix: String) -> NSRange? {
        if let range = text.range(of: prefix) {
            return NSRange(range, in: text)
        }
        return nil
    }
    
    /// Apply highlighting to an NSAttributedString
    /// - Parameters:
    ///   - text: The markdown text
    ///   - font: The base font to use
    /// - Returns: An attributed string with markdown highlighting applied
    static func attributedString(from text: String, with font: NSFont = NSFont(name: "Menlo", size: 13) ?? NSFont.systemFont(ofSize: 13)) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: draculaColors.text
        ])
        
        let highlights = highlight(text: text)
        
        for highlight in highlights {
            attributedString.addAttribute(.foregroundColor, value: highlight.color, range: highlight.range)
            
            // Apply bold formatting if needed
            if highlight.isBold {
                let boldFont = NSFont(name: "Menlo-Bold", size: font.pointSize) ?? NSFont.boldSystemFont(ofSize: font.pointSize)
                attributedString.addAttribute(.font, value: boldFont, range: highlight.range)
            }
        }
        
        return attributedString
    }
}
