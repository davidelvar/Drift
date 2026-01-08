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
        
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.string != text {
            nsView.string = text
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
        
        private func applyMarkdownHighlighting(to textView: NSTextView) {
            let fullRange = NSRange(location: 0, length: textView.string.count)
            let attributedString = NSMutableAttributedString(string: textView.string)
            
            // Reset all attributes
            attributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
            
            let text = textView.string as NSString
            let lines = text.components(separatedBy: .newlines)
            var currentLocation = 0
            
            for line in lines {
                let lineRange = NSRange(location: currentLocation, length: line.count)
                
                // Headings
                if line.hasPrefix("#") {
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: lineRange)
                }
                
                // Bold **text**
                findAndHighlight(in: attributedString, pattern: "\\*\\*(.+?)\\*\\*", color: NSColor.systemOrange, range: lineRange)
                
                // Italic *text*
                findAndHighlight(in: attributedString, pattern: "_(.+?)_", color: NSColor.systemGreen, range: lineRange)
                
                // Inline code `code`
                findAndHighlight(in: attributedString, pattern: "`(.+?)`", color: NSColor.systemRed, range: lineRange)
                
                // Links [text](url)
                findAndHighlight(in: attributedString, pattern: "\\[(.+?)\\]\\((.+?)\\)", color: NSColor.systemBlue, range: lineRange)
                
                // Blockquotes
                if line.hasPrefix(">") {
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemGray, range: lineRange)
                }
                
                // Code blocks
                if line.hasPrefix("```") {
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: lineRange)
                }
                
                // Lists
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("-") || 
                   line.trimmingCharacters(in: .whitespaces).hasPrefix("*") ||
                   line.trimmingCharacters(in: .whitespaces).hasPrefix("+") {
                    let dashRange = NSRange(location: currentLocation + line.count - line.trimmingCharacters(in: .whitespaces).count,
                                           length: 1)
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemCyan, range: dashRange)
                }
                
                currentLocation += line.count + 1 // +1 for newline
            }
            
            // Apply the attributed string without losing undo/redo
            let savedSelectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedString)
            textView.setSelectedRange(savedSelectedRange)
        }
        
        private func findAndHighlight(in attributedString: NSMutableAttributedString, pattern: String, color: NSColor, range: NSRange) {
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
