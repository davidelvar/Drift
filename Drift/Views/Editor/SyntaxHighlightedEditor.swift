//
//  SyntaxHighlightedEditor.swift
//  Drift
//
//  Custom text editor with Markdown syntax highlighting
//

import SwiftUI
import AppKit

struct SyntaxHighlightedEditor: NSViewRepresentable {
    @Binding var text: String
    var font: String = "Menlo"
    var fontSize: CGFloat = 15
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.font = NSFont(name: font, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.isRichText = true
        textView.allowsUndo = true
        textView.enabledTextCheckingTypes = 0
        textView.string = text
        
        // Apply initial highlighting
        context.coordinator.applyMarkdownHighlighting(to: textView)
        
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.string != text {
            nsView.string = text
            context.coordinator.applyMarkdownHighlighting(to: nsView)
        }
        
        if let currentFont = nsView.font, currentFont.fontName != font || currentFont.pointSize != fontSize {
            nsView.font = NSFont(name: font, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            self._text = text
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
            
            // Apply syntax highlighting
            applyMarkdownHighlighting(to: textView)
        }
        
        func applyMarkdownHighlighting(to textView: NSTextView) {
            let string = textView.string
            guard !string.isEmpty else { return }
            
            let attributedString = NSMutableAttributedString(string: string)
            let fullRange = NSRange(location: 0, length: string.count)
            
            // Set default font and color for all text
            let defaultFont = textView.font ?? NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            attributedString.addAttribute(.font, value: defaultFont, range: fullRange)
            attributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
            
            let nsString = string as NSString
            let lines = nsString.components(separatedBy: .newlines)
            var currentLocation = 0
            
            for line in lines {
                let lineRange = NSRange(location: currentLocation, length: line.count)
                
                // Headings - blue
                if line.hasPrefix("#") {
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: lineRange)
                }
                
                // Bold **text** - orange
                findAndHighlightPattern(in: attributedString, pattern: "\\*\\*(.+?)\\*\\*", color: NSColor.systemOrange, range: lineRange)
                
                // Italic *text* or _text_ - green
                findAndHighlightPattern(in: attributedString, pattern: "_(.+?)_", color: NSColor.systemGreen, range: lineRange)
                findAndHighlightPattern(in: attributedString, pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", color: NSColor.systemGreen, range: lineRange)
                
                // Inline code `code` - red
                findAndHighlightPattern(in: attributedString, pattern: "`(.+?)`", color: NSColor.systemRed, range: lineRange)
                
                // Links [text](url) - blue
                findAndHighlightPattern(in: attributedString, pattern: "\\[(.+?)\\]\\((.+?)\\)", color: NSColor.systemBlue, range: lineRange)
                
                // Blockquotes - gray
                if line.hasPrefix(">") {
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemGray, range: lineRange)
                }
                
                // Code blocks - purple
                if line.hasPrefix("```") {
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: lineRange)
                }
                
                // Lists - cyan
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("-") || trimmed.hasPrefix("*") || trimmed.hasPrefix("+") {
                    let startOffset = line.count - trimmed.count
                    let dashRange = NSRange(location: currentLocation + startOffset, length: 1)
                    if dashRange.location + dashRange.length <= attributedString.length {
                        attributedString.addAttribute(.foregroundColor, value: NSColor.systemCyan, range: dashRange)
                    }
                }
                
                currentLocation += line.count + 1 // +1 for newline
            }
            
            // Apply the attributed string without losing undo/redo
            let savedSelectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedString)
            
            // Restore selection if it's still valid
            if savedSelectedRange.location <= textView.string.count {
                textView.setSelectedRange(savedSelectedRange)
            }
        }
        
        private func findAndHighlightPattern(in attributedString: NSMutableAttributedString, pattern: String, color: NSColor, range: NSRange) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
            
            let matches = regex.matches(in: attributedString.string, options: [], range: range)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
    }
}

#Preview {
    @State var text = """
    # Hello Markdown
    
    This is **bold** and this is *italic*.
    
    - List item 1
    - List item 2
    
    `inline code here`
    
    > A blockquote
    
    [Link text](https://example.com)
    """
    
    return SyntaxHighlightedEditor(text: $text)
        .frame(height: 400)
        .padding()
}
