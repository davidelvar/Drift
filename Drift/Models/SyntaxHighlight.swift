//
//  SyntaxHighlight.swift
//  Drift
//
//  Shared model for syntax highlighting across services
//

import Foundation
import AppKit

/// Represents a range of text with syntax highlighting attributes
struct SyntaxHighlight {
    let range: NSRange
    let attributes: [NSAttributedString.Key: Any]
    let priority: Int
    
    /// Initialize with a color and priority
    init(range: NSRange, color: NSColor, priority: Int = 5) {
        self.range = range
        self.attributes = [.foregroundColor: color]
        self.priority = priority
    }
    
    /// Initialize with custom attributes
    init(range: NSRange, attributes: [NSAttributedString.Key: Any], priority: Int = 5) {
        self.range = range
        self.attributes = attributes
        self.priority = priority
    }
}
