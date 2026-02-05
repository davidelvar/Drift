//
//  SyntaxHighlightedEditor.swift
//  Drift
//
//  Custom text editor with Markdown syntax highlighting
//

import SwiftUI
import AppKit

// MARK: - Custom Text View for Task List Handling

class InteractiveMarkdownTextView: NSTextView {
    weak var interactionDelegate: InteractiveMarkdownTextViewDelegate?
    
    override func mouseDown(with event: NSEvent) {
        // Get click location
        let clickPoint = convert(event.locationInWindow, from: nil)
        guard let characterIndex = layoutManager?.characterIndex(for: clickPoint, in: textContainer!, fractionOfDistanceBetweenInsertionPoints: nil) else {
            super.mouseDown(with: event)
            return
        }
        
        // Check if this was a double-click
        if event.clickCount == 1 {
            // Let the delegate handle potential task list clicks
            interactionDelegate?.markdownTextView(self, didClickAt: characterIndex)
        }
        
        // Always pass to super for normal text selection behavior
        super.mouseDown(with: event)
    }
}

protocol InteractiveMarkdownTextViewDelegate: AnyObject {
    func markdownTextView(_ textView: InteractiveMarkdownTextView, didClickAt location: Int)
}

// MARK: - Line Number Ruler View
class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?
    private let charWidth: CGFloat = 8
    private let backgroundColor = NSColor(red: 0.09, green: 0.09, blue: 0.12, alpha: 1.0) // #161618
    
    init(scrollView: NSScrollView, textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.ruleThickness = 50
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        backgroundColor.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
        
        guard let textView = textView, let layoutManager = textView.layoutManager else { return }
        
        let context = NSGraphicsContext.current?.cgContext
        let textFont = textView.font ?? NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        let lineHeight = layoutManager.defaultLineHeight(for: textFont)
        
        let visibleRect = scrollView?.documentView?.visibleRect ?? .zero
        let contentOffset = textView.bounds.origin.y
        let firstVisibleLine = Int((visibleRect.origin.y - contentOffset) / lineHeight)
        let lastVisibleLine = Int((visibleRect.origin.y + visibleRect.height - contentOffset) / lineHeight) + 1
        
        let lineCount = textView.string.components(separatedBy: .newlines).count
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        
        let textColor = NSColor(red: 0.576, green: 0.635, blue: 0.792, alpha: 1.0) // #92a2ca
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        
        for lineNumber in max(0, firstVisibleLine)...min(lineCount, lastVisibleLine) {
            let yPosition = CGFloat(lineNumber) * lineHeight + contentOffset
            let lineRect = CGRect(x: 0, y: yPosition, width: ruleThickness - 4, height: lineHeight)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            let lineString = NSAttributedString(string: "\(lineNumber + 1)", attributes: attributes)
            lineString.draw(in: lineRect)
        }
    }
}

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
        
        let textView = InteractiveMarkdownTextView()
        textView.delegate = context.coordinator
        textView.interactionDelegate = context.coordinator
        textView.font = NSFont(name: font, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = DraculaTheme.foreground
        textView.backgroundColor = DraculaTheme.background
        textView.isRichText = true
        textView.allowsUndo = true
        textView.enabledTextCheckingTypes = 0
        textView.string = text
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true  // Allow horizontal resizing to prevent line wrapping
        textView.autoresizingMask = [.width, .height]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(width: 8, height: 16) // Left padding for line numbers + vertical padding
        
        // Configure text container to NOT wrap
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = false
            textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        
        // Store textView in coordinator for later access
        context.coordinator.textView = textView
        
        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true  // Enable horizontal scrolling since we're not wrapping
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = DraculaTheme.background
        
        // Add line number ruler
        let lineNumberView = LineNumberRulerView(scrollView: scrollView, textView: textView)
        scrollView.verticalRulerView = lineNumberView
        scrollView.rulersVisible = true
        
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
            // Preserve scroll position during text update
            let scrollView = nsView
            let previousScroll = scrollView.documentVisibleRect.origin
            let previousSelectedRange = textView.selectedRange
            
            textView.string = text
            context.coordinator.applyMarkdownHighlighting(to: textView)
            
            // Restore scroll position and selection
            if previousScroll != .zero {
                scrollView.contentView.scroll(to: previousScroll)
            }
            if previousSelectedRange.location <= textView.string.count {
                textView.setSelectedRange(previousSelectedRange)
            }
        }
        
        if let currentFont = textView.font, currentFont.fontName != font || currentFont.pointSize != fontSize {
            textView.font = NSFont(name: font, size: fontSize) ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, InteractiveMarkdownTextViewDelegate {
        @Binding var text: String
        var textView: NSTextView?
        private let taskListManager = TaskListInteractivityManager()
        
        init(text: Binding<String>) {
            self._text = text
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
            
            // Apply syntax highlighting
            applyMarkdownHighlighting(to: textView)
        }
        
        /// Handle task list checkbox clicks
        /// Called when user clicks on a checkbox in the editor
        func handleTaskListClick(in textView: NSTextView, at location: Int) {
            guard textView.textStorage != nil else { return }
            
            // Try to toggle the checkbox
            if taskListManager.toggleTaskAtLocation(in: textView.textStorage!, location: location) {
                // Update the text binding
                text = textView.string
                
                // Register undo action
                let undoManager = textView.undoManager
                undoManager?.registerUndo(withTarget: self) { target in
                    // Redo action: toggle again
                    target.handleTaskListClick(in: textView, at: location)
                }
                
                // Re-apply highlighting to show updated state
                applyMarkdownHighlighting(to: textView)
            }
        }
        
        // MARK: - InteractiveMarkdownTextViewDelegate
        
        func markdownTextView(_ textView: InteractiveMarkdownTextView, didClickAt location: Int) {
            // Try to handle as task list click
            if taskListManager.taskListItemAt(in: textView.textStorage!, location: location) != nil {
                handleTaskListClick(in: textView, at: location)
            }
        }
        
        func applyMarkdownHighlighting(to textView: NSTextView) {
            let string = textView.string
            guard !string.isEmpty else { return }
            
            // Preserve scroll and selection state
            let scrollView = textView.enclosingScrollView
            let previousScroll = scrollView?.documentVisibleRect.origin ?? .zero
            let previousSelectedRange = textView.selectedRange
            
            let attributedString = NSMutableAttributedString(string: string)
            let fullRange = NSRange(location: 0, length: attributedString.length)
            
            // Set default font and color for all text
            let defaultFont = textView.font ?? NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            attributedString.addAttribute(.font, value: defaultFont, range: fullRange)
            attributedString.addAttribute(.foregroundColor, value: DraculaTheme.foreground, range: fullRange)
            
            // STEP 1: Find and highlight code blocks FIRST (they take priority)
            let codeBlockRanges = highlightCodeBlocks(in: attributedString)

            // STEP 2: Highlight inline code (before other patterns that might interfere)
            highlightInlineCode(in: attributedString, excludeRanges: codeBlockRanges)

            // STEP 3: Apply other markdown highlighting, excluding code blocks

            // Headers (# text) - cyan
            applyRegexHighlighting(
                to: attributedString,
                pattern: "^#+\\s+.*$",
                color: DraculaTheme.cyan,
                multiline: true,
                excludeRanges: codeBlockRanges
            )
            
            // Bold **text** - pink
            applyRegexHighlighting(
                to: attributedString,
                pattern: "\\*\\*[^*]+(\\*[^*]+)*\\*\\*",
                color: DraculaTheme.pink,
                multiline: false,
                excludeRanges: codeBlockRanges
            )
            
            // Italic _text_ - purple (skip inside code blocks)
            applyRegexHighlighting(
                to: attributedString,
                pattern: "_[^_]+_",
                color: DraculaTheme.purple,
                multiline: false,
                excludeRanges: codeBlockRanges
            )
            
            // Links [text](url) - cyan
            applyRegexHighlighting(
                to: attributedString,
                pattern: "\\[[^\\]]+\\]\\([^)]+\\)",
                color: DraculaTheme.cyan,
                multiline: false,
                excludeRanges: codeBlockRanges
            )
            
            // Blockquotes (> text) - comment color (gray)
            applyRegexHighlighting(
                to: attributedString,
                pattern: "^>\\s+.*$",
                color: DraculaTheme.comment,
                multiline: true,
                excludeRanges: codeBlockRanges
            )

            // Task list checkboxes - yellow
            highlightTaskListCheckboxes(in: attributedString, string: string, excludeRanges: codeBlockRanges)

            // Table separators and pipes - green
            highlightTableElements(in: attributedString, string: string, excludeRanges: codeBlockRanges)

            // Apply the attributed string without losing undo/redo
            textView.textStorage?.setAttributedString(attributedString)
            
            // Restore selection and scroll position if they're still valid
            if previousSelectedRange.location <= textView.string.count {
                textView.setSelectedRange(previousSelectedRange)
            }
            
            // Restore scroll position if the scroll view exists
            if let scrollView = scrollView, previousScroll != .zero {
                scrollView.contentView.scroll(to: previousScroll)
            }
        }
        
        private func highlightCodeBlocks(in attributedString: NSMutableAttributedString) -> [NSRange] {
            var codeBlockRanges: [NSRange] = []
            let nsString = attributedString.string as NSString
            let totalLength = nsString.length
            guard totalLength > 0 else { return codeBlockRanges }

            // Parse line by line to find code fences
            var lineStart = 0
            var fenceLines: [(range: NSRange, isOpening: Bool)] = []

            while lineStart < totalLength {
                // Find end of current line
                let lineRange = nsString.lineRange(for: NSRange(location: lineStart, length: 0))
                let lineText = nsString.substring(with: lineRange)

                // Check if line starts with ``` (allowing leading whitespace)
                let trimmedLine = lineText.trimmingCharacters(in: .whitespaces)
                if trimmedLine.hasPrefix("```") {
                    // This is a fence line - trim trailing newline for the range
                    var fenceRange = lineRange
                    if lineText.hasSuffix("\n") {
                        fenceRange.length -= 1
                    }
                    if lineText.hasSuffix("\r\n") {
                        fenceRange.length -= 1 // Already subtracted 1 for \n
                    }
                    fenceLines.append((range: fenceRange, isOpening: fenceLines.count % 2 == 0))
                }

                lineStart = lineRange.location + lineRange.length
            }

            // Pair up fences and highlight
            var i = 0
            while i + 1 < fenceLines.count {
                let opening = fenceLines[i]
                let closing = fenceLines[i + 1]

                // Calculate the full block range (from start of opening to end of closing)
                let blockStart = opening.range.location
                let blockEnd = closing.range.location + closing.range.length
                let blockRange = NSRange(location: blockStart, length: blockEnd - blockStart)

                if blockRange.location + blockRange.length <= totalLength {
                    codeBlockRanges.append(blockRange)

                    // Color fence lines green
                    attributedString.addAttribute(.foregroundColor, value: DraculaTheme.green, range: opening.range)
                    attributedString.addAttribute(.foregroundColor, value: DraculaTheme.green, range: closing.range)

                    // Color the content between fences cyan
                    // Content starts after the opening fence line (including its newline)
                    let contentStart = opening.range.location + opening.range.length + 1 // +1 for newline
                    let contentEnd = closing.range.location
                    if contentEnd > contentStart && contentStart < totalLength {
                        let contentRange = NSRange(location: contentStart, length: contentEnd - contentStart)
                        attributedString.addAttribute(.foregroundColor, value: DraculaTheme.cyan, range: contentRange)
                    }
                }

                i += 2
            }

            return codeBlockRanges
        }

        private func highlightInlineCode(in attributedString: NSMutableAttributedString, excludeRanges: [NSRange]) {
            let nsString = attributedString.string as NSString
            let totalLength = nsString.length
            guard totalLength > 0 else { return }

            // Find inline code by scanning for backticks
            // We need to handle: `code` but not ``` or `` (escaped)
            var i = 0
            while i < totalLength {
                let char = nsString.character(at: i)

                // Check for backtick
                if char == 0x60 { // backtick character '`'
                    // Check if this is a triple backtick (skip it)
                    if i + 2 < totalLength &&
                       nsString.character(at: i + 1) == 0x60 &&
                       nsString.character(at: i + 2) == 0x60 {
                        // Skip past the triple backtick
                        i += 3
                        continue
                    }

                    // Check if this is a double backtick (skip it)
                    if i + 1 < totalLength && nsString.character(at: i + 1) == 0x60 {
                        i += 2
                        continue
                    }

                    // This is a single backtick - find the closing one
                    let openingPos = i
                    i += 1

                    // Look for closing backtick on the same line
                    while i < totalLength {
                        let nextChar = nsString.character(at: i)
                        if nextChar == 0x0A || nextChar == 0x0D { // newline
                            break // No closing backtick on this line
                        }
                        if nextChar == 0x60 { // closing backtick
                            // Make sure it's not a double/triple backtick
                            let isDouble = i + 1 < totalLength && nsString.character(at: i + 1) == 0x60

                            if !isDouble {
                                // Found valid inline code
                                let codeRange = NSRange(location: openingPos, length: i - openingPos + 1)

                                // Check if it overlaps with any code block
                                var isExcluded = false
                                for excludeRange in excludeRanges {
                                    if codeRange.location >= excludeRange.location &&
                                       codeRange.location + codeRange.length <= excludeRange.location + excludeRange.length {
                                        isExcluded = true
                                        break
                                    }
                                }

                                if !isExcluded {
                                    attributedString.addAttribute(.foregroundColor, value: DraculaTheme.yellow, range: codeRange)
                                }
                                i += 1
                                break
                            }
                        }
                        i += 1
                    }
                } else {
                    i += 1
                }
            }
        }
        
        /// Get ranges of all code blocks in the string to avoid highlighting inside them
        private func getCodeBlockRanges(in string: String) -> [NSRange] {
            var codeBlockRanges: [NSRange] = []
            let nsString = string as NSString
            let totalLength = nsString.length
            guard totalLength > 0 else { return codeBlockRanges }

            // Find all ``` occurrences that are valid fences
            var fenceLocations: [(location: Int, lineEnd: Int)] = []
            var searchStart = 0

            while searchStart < totalLength {
                let searchRange = NSRange(location: searchStart, length: totalLength - searchStart)
                let foundRange = nsString.range(of: "```", options: [], range: searchRange)

                if foundRange.location == NSNotFound { break }

                // Check if at line start or preceded only by whitespace
                var isValidFence = foundRange.location == 0 ||
                    nsString.substring(with: NSRange(location: foundRange.location - 1, length: 1)) == "\n"

                if !isValidFence && foundRange.location > 0 {
                    var lineStart = foundRange.location - 1
                    while lineStart > 0 && nsString.substring(with: NSRange(location: lineStart - 1, length: 1)) != "\n" {
                        lineStart -= 1
                    }
                    if lineStart < foundRange.location {
                        let prefix = nsString.substring(with: NSRange(location: lineStart, length: foundRange.location - lineStart))
                        isValidFence = prefix.trimmingCharacters(in: .whitespaces).isEmpty
                    }
                }

                if isValidFence {
                    var lineEnd = foundRange.location + foundRange.length
                    while lineEnd < totalLength && nsString.substring(with: NSRange(location: lineEnd, length: 1)) != "\n" {
                        lineEnd += 1
                    }
                    fenceLocations.append((location: foundRange.location, lineEnd: lineEnd))
                }

                searchStart = foundRange.location + foundRange.length
            }

            // Pair fences
            var i = 0
            while i + 1 < fenceLocations.count {
                let opening = fenceLocations[i]
                let closing = fenceLocations[i + 1]

                var openingLineStart = opening.location
                while openingLineStart > 0 && nsString.substring(with: NSRange(location: openingLineStart - 1, length: 1)) != "\n" {
                    openingLineStart -= 1
                }

                let blockRange = NSRange(location: openingLineStart, length: closing.lineEnd - openingLineStart)
                if blockRange.location + blockRange.length <= totalLength {
                    codeBlockRanges.append(blockRange)
                }

                i += 2
            }

            return codeBlockRanges
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
                
                let matches = regex.matches(in: codeString, options: [], range: NSRange(location: 0, length: (codeString as NSString).length))
                
                for match in matches {
                    let adjustedRange = NSRange(location: baseRange.location + match.range.location, length: match.range.length)
                    if adjustedRange.location + adjustedRange.length <= attributedString.length {
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

            let matches = regex.matches(in: codeString, options: [], range: NSRange(location: 0, length: (codeString as NSString).length))
            
            for match in matches {
                let adjustedRange = NSRange(location: baseRange.location + match.range.location, length: match.range.length)
                if adjustedRange.location + adjustedRange.length <= attributedString.length {
                    attributedString.addAttribute(.foregroundColor, value: color, range: adjustedRange)
                }
            }
        }

        private func applyRegexHighlighting(to attributedString: NSMutableAttributedString, pattern: String, color: NSColor, multiline: Bool, excludeRanges: [NSRange] = []) {
            var options: NSRegularExpression.Options = [.useUnicodeWordBoundaries]
            if multiline {
                options.insert(.anchorsMatchLines)
            }

            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                return
            }

            let fullRange = NSRange(location: 0, length: attributedString.length)
            let matches = regex.matches(in: attributedString.string, options: [], range: fullRange)

            for match in matches {
                // Check if this match overlaps with any excluded range (code block)
                var isInExcludedRange = false
                for excludeRange in excludeRanges {
                    let matchStart = match.range.location
                    let matchEnd = match.range.location + match.range.length
                    let excludeStart = excludeRange.location
                    let excludeEnd = excludeRange.location + excludeRange.length

                    // Check if match is completely inside exclude range
                    if matchStart >= excludeStart && matchEnd <= excludeEnd {
                        isInExcludedRange = true
                        break
                    }
                    // Check if match overlaps with exclude range at all
                    if matchStart < excludeEnd && matchEnd > excludeStart {
                        isInExcludedRange = true
                        break
                    }
                }

                if isInExcludedRange {
                    continue
                }

                attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }

        private func highlightTaskListCheckboxes(in attributedString: NSMutableAttributedString, string: String, excludeRanges: [NSRange]) {
            // Match task list checkboxes: - [ ] or - [x] or * [ ] or + [ ]
            let pattern = "^\\s*[-*+]\\s+\\[[xX ]\\]"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
                return
            }

            let nsString = string as NSString
            let fullRange = NSRange(location: 0, length: nsString.length)
            let matches = regex.matches(in: string, options: [], range: fullRange)

            for match in matches {
                // Check if inside code block
                var isInExcludedRange = false
                for excludeRange in excludeRanges {
                    let matchStart = match.range.location
                    let matchEnd = match.range.location + match.range.length
                    let excludeStart = excludeRange.location
                    let excludeEnd = excludeRange.location + excludeRange.length
                    if (matchStart >= excludeStart && matchEnd <= excludeEnd) ||
                       (matchStart < excludeEnd && matchEnd > excludeStart) {
                        isInExcludedRange = true
                        break
                    }
                }
                if isInExcludedRange { continue }

                let matchText = nsString.substring(with: match.range)
                if let bracketIndex = matchText.firstIndex(of: "[") {
                    let bracketOffset = matchText.distance(from: matchText.startIndex, to: bracketIndex)
                    let bracketRange = NSRange(location: match.range.location + bracketOffset, length: 3)
                    if bracketRange.location + bracketRange.length <= attributedString.length {
                        attributedString.addAttribute(.foregroundColor, value: DraculaTheme.yellow, range: bracketRange)
                    }
                }
            }
        }

        private func highlightTableElements(in attributedString: NSMutableAttributedString, string: String, excludeRanges: [NSRange]) {
            let nsString = string as NSString

            // Helper function to check if a range is excluded
            func isExcluded(_ range: NSRange) -> Bool {
                for excludeRange in excludeRanges {
                    let matchStart = range.location
                    let matchEnd = range.location + range.length
                    let excludeStart = excludeRange.location
                    let excludeEnd = excludeRange.location + excludeRange.length
                    if (matchStart >= excludeStart && matchEnd <= excludeEnd) ||
                       (matchStart < excludeEnd && matchEnd > excludeStart) {
                        return true
                    }
                }
                return false
            }

            // Match full table separator lines: |:---|---:|:---:|---|
            let separatorPattern = "^\\s*\\|(?:\\s*:?-+:?\\s*\\|)+\\s*$"
            if let separatorRegex = try? NSRegularExpression(pattern: separatorPattern, options: [.anchorsMatchLines]) {
                let fullRange = NSRange(location: 0, length: nsString.length)
                let matches = separatorRegex.matches(in: string, options: [], range: fullRange)

                for match in matches {
                    if isExcluded(match.range) { continue }
                    if match.range.location + match.range.length <= attributedString.length {
                        attributedString.addAttribute(.foregroundColor, value: DraculaTheme.green, range: match.range)
                    }
                }
            }

            // Highlight pipes in table rows
            let pipePattern = "^\\s*\\|.*\\|\\s*$"
            if let pipeRegex = try? NSRegularExpression(pattern: pipePattern, options: [.anchorsMatchLines]) {
                let fullRange = NSRange(location: 0, length: nsString.length)
                let matches = pipeRegex.matches(in: string, options: [], range: fullRange)

                for match in matches {
                    if isExcluded(match.range) { continue }

                    // Highlight only the pipe characters
                    let lineText = nsString.substring(with: match.range)
                    var offset = match.range.location
                    for char in lineText {
                        if char == "|" {
                            let pipeRange = NSRange(location: offset, length: 1)
                            if pipeRange.location + pipeRange.length <= attributedString.length {
                                attributedString.addAttribute(.foregroundColor, value: DraculaTheme.green, range: pipeRange)
                            }
                        }
                        offset += 1
                    }
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
        .padding(.horizontal, 8)
//        .padding()
}
