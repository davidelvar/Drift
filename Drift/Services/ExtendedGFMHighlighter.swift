//
//  ExtendedGFMHighlighter.swift
//  Drift
//
//  Service for highlighting extended GFM features: autolinks, footnotes, callouts
//

import Foundation
import AppKit

// MARK: - Callout Types

enum CalloutType: String, CaseIterable {
    case note = "NOTE"
    case warning = "WARNING"
    case important = "IMPORTANT"
    case tip = "TIP"
    case caution = "CAUTION"
    
    var color: NSColor {
        switch self {
        case .note: return NSColor(hex: "#8be9fd")!      // Cyan
        case .warning: return NSColor(hex: "#f1fa8c")!    // Yellow
        case .important: return NSColor(hex: "#ff79c6")!  // Pink
        case .tip: return NSColor(hex: "#50fa7b")!        // Green
        case .caution: return NSColor(hex: "#ff9580")!    // Orange
        }
    }
    
    var backgroundColor: NSColor {
        // Semi-transparent version of color
        let color = self.color
        return color.withAlphaComponent(0.1)
    }
}

// MARK: - Highlight Result

// MARK: - Extended GFM Highlighter

@MainActor
class ExtendedGFMHighlighter {
    
    // MARK: - Regex Patterns
    
    /// Autolink pattern: <https://example.com> or <user@example.com>
    private let autolinkPattern = try! NSRegularExpression(
        pattern: "<([a-zA-Z][a-zA-Z0-9+.-]*://[^>]+|[^<>@]+@[^<>]+)>",
        options: []
    )
    
    /// Footnote reference pattern: [^label]
    private let footnoteRefPattern = try! NSRegularExpression(
        pattern: "\\[\\^([^\\]]+)\\]",
        options: []
    )
    
    /// Footnote definition pattern: [^label]: definition
    private let footnoteDefPattern = try! NSRegularExpression(
        pattern: "^\\[\\^([^\\]]+)\\]:\\s+(.*)$",
        options: [.anchorsMatchLines]
    )
    
    /// Callout pattern: > [!TYPE]
    private let calloutPattern = try! NSRegularExpression(
        pattern: ">\\s+\\[!([A-Z]+)\\]",
        options: []
    )
    
    // MARK: - Dracula Theme Colors
    
    private let draculaColors = (
        cyan: NSColor(hex: "#8be9fd")!,
        pink: NSColor(hex: "#ff79c6")!,
        green: NSColor(hex: "#50fa7b")!,
        yellow: NSColor(hex: "#f1fa8c")!,
        orange: NSColor(hex: "#ffb86c")!,
        purple: NSColor(hex: "#bd93f9")!,
        gray: NSColor(hex: "#6272a4")!
    )
    
    // MARK: - Public API
    
    /// Highlight autolinks (e.g., <https://github.com>)
    /// - Parameter text: The text to highlight
    /// - Returns: Array of SyntaxHighlight for autolinks
    func highlightAutolinks(_ text: String) -> [SyntaxHighlight] {
        let nsText = text as NSString
        let matches = autolinkPattern.matches(
            in: text,
            range: NSRange(location: 0, length: nsText.length)
        )
        
        return matches.map { match in
            SyntaxHighlight(
                range: match.range,
                color: draculaColors.cyan,
                priority: 7
            )
        }
    }
    
    /// Highlight footnotes (both references and definitions)
    /// - Parameter text: The text to highlight
    /// - Returns: Array of SyntaxHighlight for footnotes
    func highlightFootnotes(_ text: String) -> [SyntaxHighlight] {
        var highlights: [SyntaxHighlight] = []
        let nsText = text as NSString
        
        // Footnote references: [^1], [^note], etc.
        let refMatches = footnoteRefPattern.matches(
            in: text,
            range: NSRange(location: 0, length: nsText.length)
        )
        
        for match in refMatches {
            highlights.append(
                SyntaxHighlight(
                    range: match.range,
                    color: draculaColors.pink,
                    priority: 6
                )
            )
        }
        
        // Footnote definitions: [^1]: definition
        let lines = text.components(separatedBy: .newlines)
        var lineOffset = 0
        
        for line in lines {
            let defMatches = footnoteDefPattern.matches(
                in: line,
                range: NSRange(location: 0, length: (line as NSString).length)
            )
            
            for match in defMatches {
                // Highlight the label part
                let absoluteRange = NSRange(
                    location: lineOffset + match.range.location,
                    length: match.range.length
                )
                
                highlights.append(
                    SyntaxHighlight(
                        range: absoluteRange,
                        color: draculaColors.pink,
                        priority: 6
                    )
                )
            }
            
            lineOffset += line.count + 1  // +1 for newline
        }
        
        return highlights
    }
    
    /// Highlight callouts (e.g., > [!NOTE])
    /// - Parameter text: The text to highlight
    /// - Returns: Array of SyntaxHighlight for callouts
    func highlightCallouts(_ text: String) -> [SyntaxHighlight] {
        let nsText = text as NSString
        let matches = calloutPattern.matches(
            in: text,
            range: NSRange(location: 0, length: nsText.length)
        )
        
        return matches.compactMap { match in
            // Get the callout type
            guard match.numberOfRanges >= 2 else { return nil }
            
            let typeRange = match.range(at: 1)
            let typeStr = nsText.substring(with: typeRange)
            
            guard let calloutType = CalloutType(rawValue: typeStr) else {
                return nil
            }
            
            return SyntaxHighlight(
                range: match.range,
                attributes: [
                    .foregroundColor: calloutType.color,
                    .font: NSFont(name: "Monaco", size: 13) ?? NSFont.systemFont(ofSize: 13, weight: .bold),
                    .backgroundColor: calloutType.backgroundColor
                ],
                priority: 8
            )
        }
    }
    
    /// Merge extended highlights with existing markdown highlights
    /// Ensures proper priority and prevents overlaps
    /// - Parameters:
    ///   - markdownHighlights: Highlights from UnifiedMarkdownHighlighter
    ///   - extendedHighlights: Highlights from this service
    /// - Returns: Merged and conflict-resolved array of highlights
    func mergeHighlights(
        _ markdownHighlights: [SyntaxHighlight],
        with extendedHighlights: [SyntaxHighlight]
    ) -> [SyntaxHighlight] {
        
        // Combine all highlights
        var allHighlights = markdownHighlights + extendedHighlights
        
        // Sort by priority (higher first), then by location
        allHighlights.sort { a, b in
            if a.priority != b.priority {
                return a.priority > b.priority
            }
            return a.range.location < b.range.location
        }
        
        // Remove overlapping ranges (keep higher priority)
        var resolved: [SyntaxHighlight] = []
        var coveredRanges: [NSRange] = []
        
        for highlight in allHighlights {
            // Check if this range overlaps with already covered range
            let overlaps = coveredRanges.contains { covered in
                let rangeEnd = highlight.range.location + highlight.range.length
                let coveredEnd = covered.location + covered.length
                
                // Check for overlap
                return !(rangeEnd <= covered.location || highlight.range.location >= coveredEnd)
            }
            
            if !overlaps {
                resolved.append(highlight)
                coveredRanges.append(highlight.range)
            }
        }
        
        return resolved
    }
    
    /// Get all extended features in text
    /// - Parameter text: The text to analyze
    /// - Returns: Dictionary with counts of each feature type
    func analyzeExtendedFeatures(_ text: String) -> [String: Int] {
        let nsText = text as NSString
        
        let autolinkCount = autolinkPattern.numberOfMatches(
            in: text,
            range: NSRange(location: 0, length: nsText.length)
        )
        
        let footnoteRefCount = footnoteRefPattern.numberOfMatches(
            in: text,
            range: NSRange(location: 0, length: nsText.length)
        )
        
        let calloutCount = calloutPattern.numberOfMatches(
            in: text,
            range: NSRange(location: 0, length: nsText.length)
        )
        
        return [
            "autolinks": autolinkCount,
            "footnotes": footnoteRefCount,
            "callouts": calloutCount
        ]
    }
}

// MARK: - NSColor Extension (Hex Support)

extension NSColor {
    /// Initialize NSColor from hex string (e.g., "#ff79c6")
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespaces).uppercased()
        
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        guard hexString.count == 6 else { return nil }
        
        var rgbValue: UInt32 = 0
        Scanner(string: hexString).scanHexInt32(&rgbValue)
        
        let red = CGFloat((rgbValue >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgbValue >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgbValue & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    /// Create color with adjusted alpha
    func withAlphaComponent(_ alpha: CGFloat) -> NSColor {
        return NSColor(
            red: self.redComponent,
            green: self.greenComponent,
            blue: self.blueComponent,
            alpha: alpha
        )
    }
}
