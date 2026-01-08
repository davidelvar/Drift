//
//  SyntaxHighlightedEditor.swift
//  Drift
//
//  Custom text editor with Markdown syntax highlighting
//

import SwiftUI
import AppKit

// MARK: - Dracula Theme Colors
struct DraculaTheme {
    static let background = NSColor(red: 0.1137, green: 0.1176, blue: 0.1569, alpha: 1.0) // #1D1E28
    static let foreground = NSColor(red: 0.973, green: 0.973, blue: 0.949, alpha: 1.0) // #f8f8f2
    static let comment = NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0) // #6272a4
    static let cyan = NSColor(red: 0.549, green: 0.915, blue: 0.993, alpha: 1.0) // #8be9fd
    static let green = NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0) // #50fa7b
    static let orange = NSColor(red: 1.0, green: 0.722, blue: 0.424, alpha: 1.0) // #ffb86c
    static let pink = NSColor(red: 1.0, green: 0.474, blue: 0.778, alpha: 1.0) // #ff79c6
    static let purple = NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0) // #bd93f9
    static let red = NSColor(red: 1.0, green: 0.333, blue: 0.333, alpha: 1.0) // #ff5555
    static let yellow = NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0) // #f1fa8c
}

struct SyntaxHighlightedEditor: NSViewRepresentable {
    @Binding var text: String
    var font: String = "Menlo"
    var fontSize: CGFloat = 15
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.font = NSFont(name: font, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = DraculaTheme.foreground
        textView.backgroundColor = DraculaTheme.background
        textView.isRichText = true
        textView.allowsUndo = true
        textView.enabledTextCheckingTypes = 0
        textView.string = text
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false  // Disable horizontal resizing to enable wrapping
        textView.autoresizingMask = [.width, .height]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(width: 0, height: 16) // Vertical padding inside
        
        // Configure text container for wrapping
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
        }
        
        // Store textView in coordinator for later access
        context.coordinator.textView = textView
        
        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false  // Disable horizontal scrolling
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = DraculaTheme.background
        
        // Make scrollers more discreet
        if let verticalScroller = scrollView.verticalScroller {
            verticalScroller.alphaValue = 0.5
        }
        
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
            attributedString.addAttribute(.foregroundColor, value: DraculaTheme.foreground, range: fullRange)
            
            // Apply markdown and code highlighting with regex
            // Process in order of specificity to avoid conflicts
            
            // Headers (# text) - cyan
            applyRegexHighlighting(
                to: attributedString,
                pattern: "^#+\\s+.*$",
                color: DraculaTheme.cyan,
                multiline: true
            )
            
            // Code blocks with language (```language\n...```) - apply syntax highlighting
            highlightCodeBlocks(in: attributedString, string: string)
            
            // Inline code `text` - yellow (use non-greedy matching)
            applyRegexHighlighting(
                to: attributedString,
                pattern: "`[^`]*?`",
                color: DraculaTheme.yellow,
                multiline: false
            )
            
            // Bold **text** - pink
            applyRegexHighlighting(
                to: attributedString,
                pattern: "\\*\\*[^*]+(\\*[^*]+)*\\*\\*",
                color: DraculaTheme.pink,
                multiline: false
            )
            
            // Italic _text_ - purple
            applyRegexHighlighting(
                to: attributedString,
                pattern: "_[^_]+_",
                color: DraculaTheme.purple,
                multiline: false
            )
            
            // Links [text](url) - cyan
            applyRegexHighlighting(
                to: attributedString,
                pattern: "\\[[^\\]]+\\]\\([^)]+\\)",
                color: DraculaTheme.cyan,
                multiline: false
            )
            
            // Blockquotes (> text) - comment color (gray)
            applyRegexHighlighting(
                to: attributedString,
                pattern: "^>\\s+.*$",
                color: DraculaTheme.comment,
                multiline: true
            )
            
            // Apply the attributed string without losing undo/redo
            let savedSelectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedString)
            
            // Restore selection if it's still valid
            if savedSelectedRange.location <= textView.string.count {
                textView.setSelectedRange(savedSelectedRange)
            }
        }
        
        private func highlightCodeBlocks(in attributedString: NSMutableAttributedString, string: String) {
            let codeBlockPattern = "```(\\w*)\\n([^`]*)```"
            guard let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: [.dotMatchesLineSeparators]) else {
                return
            }
            
            let fullRange = NSRange(location: 0, length: string.count)
            let matches = regex.matches(in: string, options: [], range: fullRange)
            
            for match in matches {
                guard match.numberOfRanges >= 3 else { continue }
                
                let codeRange = match.range(at: 2)
                let languageRange = match.range(at: 1)
                
                // Get the language identifier
                var language = ""
                if languageRange.location != NSNotFound {
                    language = (string as NSString).substring(with: languageRange)
                }
                
                // Apply syntax-specific colors to code block content
                applyCodeSyntaxHighlighting(
                    to: attributedString,
                    codeRange: codeRange,
                    language: language
                )
            }
        }
        
        private func applyCodeSyntaxHighlighting(to attributedString: NSMutableAttributedString, codeRange: NSRange, language: String) {
            let codeString = (attributedString.string as NSString).substring(with: codeRange)
            
            // Define syntax patterns based on language
            switch language.lowercased() {
            case "swift", "":
                // Swift keywords - orange
                let swiftKeywords = ["func", "class", "struct", "enum", "protocol", "var", "let", "if", "else", "for", "while", "return", "import", "extension"]
                highlightKeywords(swiftKeywords, in: attributedString, baseRange: codeRange, color: DraculaTheme.orange)
                
                // String literals - green
                applyRegexHighlightingInRange(
                    to: attributedString,
                    pattern: "\"[^\"]*\"",
                    color: DraculaTheme.green,
                    baseRange: codeRange
                )
                
            case "python":
                // Python keywords - orange
                let pythonKeywords = ["def", "class", "if", "else", "for", "while", "return", "import", "from", "as"]
                highlightKeywords(pythonKeywords, in: attributedString, baseRange: codeRange, color: DraculaTheme.orange)
                
                // String literals - green
                applyRegexHighlightingInRange(
                    to: attributedString,
                    pattern: "['\"][^'\"]*['\"]",
                    color: DraculaTheme.green,
                    baseRange: codeRange
                )
                
            case "javascript", "typescript", "js", "ts":
                // JS keywords - orange
                let jsKeywords = ["function", "const", "let", "var", "if", "else", "for", "while", "return", "async", "await", "class"]
                highlightKeywords(jsKeywords, in: attributedString, baseRange: codeRange, color: DraculaTheme.orange)
                
                // String literals - green
                applyRegexHighlightingInRange(
                    to: attributedString,
                    pattern: "['\"][^'\"]*['\"]",
                    color: DraculaTheme.green,
                    baseRange: codeRange
                )
                
            default:
                // Generic code: highlight strings
                applyRegexHighlightingInRange(
                    to: attributedString,
                    pattern: "['\"][^'\"]*['\"]",
                    color: DraculaTheme.green,
                    baseRange: codeRange
                )
            }
        }
        
        private func highlightKeywords(_ keywords: [String], in attributedString: NSMutableAttributedString, baseRange: NSRange, color: NSColor) {
            let codeString = (attributedString.string as NSString).substring(with: baseRange)
            
            for keyword in keywords {
                let pattern = "\\b\(keyword)\\b"
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                    continue
                }
                
                let matches = regex.matches(in: codeString, options: [], range: NSRange(location: 0, length: codeString.count))
                
                for match in matches {
                    let adjustedRange = NSRange(location: baseRange.location + match.range.location, length: match.range.length)
                    if adjustedRange.location + adjustedRange.length <= attributedString.string.count {
                        attributedString.addAttribute(.foregroundColor, value: color, range: adjustedRange)
                    }
                }
            }
        }
        
        private func applyRegexHighlightingInRange(to attributedString: NSMutableAttributedString, pattern: String, color: NSColor, baseRange: NSRange) {
            let codeString = (attributedString.string as NSString).substring(with: baseRange)
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return
            }
            
            let matches = regex.matches(in: codeString, options: [], range: NSRange(location: 0, length: codeString.count))
            
            for match in matches {
                let adjustedRange = NSRange(location: baseRange.location + match.range.location, length: match.range.length)
                if adjustedRange.location + adjustedRange.length <= attributedString.string.count {
                    attributedString.addAttribute(.foregroundColor, value: color, range: adjustedRange)
                }
            }
        }
        
        private func applyRegexHighlighting(to attributedString: NSMutableAttributedString, pattern: String, color: NSColor, multiline: Bool) {
            var options: NSRegularExpression.Options = [.useUnicodeWordBoundaries]
            if multiline {
                options.insert(.anchorsMatchLines)
            }
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                return
            }
            
            let fullRange = NSRange(location: 0, length: attributedString.string.count)
            let matches = regex.matches(in: attributedString.string, options: [], range: fullRange)
            
            for match in matches {
                // Only apply if not already colored (skip if current color is not the default foreground)
                var shouldApply = true
                attributedString.enumerateAttributes(
                    in: match.range,
                    options: []
                ) { attrs, _, _ in
                    if let currentColor = attrs[.foregroundColor] as? NSColor,
                       currentColor != DraculaTheme.foreground {
                        shouldApply = false
                    }
                }
                
                if shouldApply {
                    attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
                }
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
