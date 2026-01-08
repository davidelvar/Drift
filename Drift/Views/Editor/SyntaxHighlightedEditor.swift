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
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.font = NSFont(name: font, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.isRichText = true
        textView.allowsUndo = true
        textView.enabledTextCheckingTypes = 0
        textView.string = text
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width, .height]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        // Store textView in coordinator for later access
        context.coordinator.textView = textView
        
        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = NSColor.textBackgroundColor
        
        // Apply initial highlighting
        context.coordinator.applyMarkdownHighlighting(to: textView)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            textView.string = text
            context.coordinator.applyMarkdownHighlighting(to: textView)
        }
        
        if let currentFont = textView.font, currentFont.fontName != font || currentFont.pointSize != fontSize {
            textView.font = NSFont(name: font, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var textView: NSTextView?
        
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
            
            // Process inline markdown highlighting only
            // Focus on: bold, italic, code, links
            highlightInlineMarkdownInDocument(in: attributedString, nsString: nsString)
            
            // Apply the attributed string without losing undo/redo
            let savedSelectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedString)
            
            // Restore selection if it's still valid
            if savedSelectedRange.location <= textView.string.count {
                textView.setSelectedRange(savedSelectedRange)
            }
        }
        
        private func highlightInlineMarkdownInDocument(in attributedString: NSMutableAttributedString, nsString: NSString) {
            let fullString = nsString as String
            let chars = Array(fullString)
            var i = 0
            
            while i < chars.count {
                // Check for links [text](url)
                if chars[i] == "[" {
                    if let closeBracket = findClosingBracket(chars: chars, start: i + 1, open: "[", close: "]"),
                       closeBracket + 1 < chars.count && chars[closeBracket + 1] == "(" {
                        if let closeParen = findClosingBracket(chars: chars, start: closeBracket + 2, open: "(", close: ")") {
                            let linkRange = NSRange(location: i, length: closeParen - i + 1)
                            if linkRange.location + linkRange.length <= attributedString.length {
                                attributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: linkRange)
                            }
                            i = closeParen + 1
                            continue
                        }
                    }
                }
                
                // Check for bold **text**
                if i + 1 < chars.count && chars[i] == "*" && chars[i + 1] == "*" {
                    if let endBold = findSubstring(chars: chars, start: i + 2, substring: "**") {
                        let boldRange = NSRange(location: i, length: endBold - i + 2)
                        if boldRange.location + boldRange.length <= attributedString.length {
                            attributedString.addAttribute(.foregroundColor, value: NSColor.systemOrange, range: boldRange)
                        }
                        i = endBold + 2
                        continue
                    }
                }
                
                // Check for italic _text_
                if chars[i] == "_" {
                    if let endItalic = findCharacter(chars: chars, start: i + 1, char: "_") {
                        let italicRange = NSRange(location: i, length: endItalic - i + 1)
                        if italicRange.location + italicRange.length <= attributedString.length {
                            attributedString.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: italicRange)
                        }
                        i = endItalic + 1
                        continue
                    }
                }
                
                // Check for inline code `code`
                if chars[i] == "`" {
                    if let endCode = findCharacter(chars: chars, start: i + 1, char: "`") {
                        let codeRange = NSRange(location: i, length: endCode - i + 1)
                        if codeRange.location + codeRange.length <= attributedString.length {
                            attributedString.addAttribute(.foregroundColor, value: NSColor.systemRed, range: codeRange)
                        }
                        i = endCode + 1
                        continue
                    }
                }
                
                i += 1
            }
        }
        
        private func findClosingBracket(chars: [Character], start: Int, open: Character, close: Character) -> Int? {
            var depth = 1
            for i in start..<chars.count {
                if chars[i] == open {
                    depth += 1
                } else if chars[i] == close {
                    depth -= 1
                    if depth == 0 {
                        return i
                    }
                }
            }
            return nil
        }
        
        private func findCharacter(chars: [Character], start: Int, char: Character) -> Int? {
            for i in start..<chars.count {
                if chars[i] == char {
                    return i
                }
            }
            return nil
        }
        
        private func findSubstring(chars: [Character], start: Int, substring: String) -> Int? {
            let subChars = Array(substring)
            guard start + subChars.count <= chars.count else { return nil }
            
            for i in start..<(chars.count - subChars.count + 1) {
                if chars[i..<(i + subChars.count)].elementsEqual(subChars) {
                    return i
                }
            }
            return nil
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
