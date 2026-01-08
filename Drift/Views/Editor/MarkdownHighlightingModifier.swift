//
//  MarkdownHighlightingModifier.swift
//  Drift
//
//  Applies markdown syntax highlighting to the CodeEditor's text view
//

import SwiftUI
import AppKit

/// A modifier that applies markdown highlighting to a CodeEditor's text
struct MarkdownHighlightingModifier: ViewModifier {
    let text: String
    let font: NSFont
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                applyHighlighting()
            }
            .onChange(of: text) { _, _ in
                applyHighlighting()
            }
    }
    
    /// Apply markdown highlighting to the active text view
    private func applyHighlighting() {
        guard let textView = NSApp.keyWindow?.firstResponder as? NSTextView else {
            return
        }
        
        // Create attributed string with highlighting
        let attributedString = MarkdownSyntaxHighlighter.attributedString(from: text, with: font)
        
        // Apply to the text view
        textView.textStorage?.setAttributedString(attributedString)
    }
}

extension View {
    /// Apply markdown syntax highlighting to the editor
    func withMarkdownHighlighting(text: String, font: NSFont = NSFont(name: "Menlo", size: 13) ?? NSFont.systemFont(ofSize: 13)) -> some View {
        modifier(MarkdownHighlightingModifier(text: text, font: font))
    }
}
