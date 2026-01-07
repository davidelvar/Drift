//
//  MarkdownRenderer.swift
//  Drift
//
//  Renders Markdown content to styled SwiftUI views
//

import SwiftUI
import AppKit

// MARK: - Main Markdown View
struct MarkdownView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                    renderBlock(block)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .textSelection(.enabled)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
    
    // MARK: - Block Types
    enum MarkdownBlock: Equatable {
        case heading(level: Int, text: String)
        case paragraph(text: String)
        case codeBlock(language: String?, code: String)
        case blockquote(text: String)
        case listItem(ordered: Bool, index: Int, text: String)
        case horizontalRule
        case empty
    }
    
    // MARK: - Parse Content into Blocks
    private func parseBlocks() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = content.components(separatedBy: .newlines)
        var i = 0
        var listIndex = 0
        var inCodeBlock = false
        var codeBlockLanguage: String? = nil
        var codeBlockLines: [String] = []
        
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Handle code blocks
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    blocks.append(.codeBlock(language: codeBlockLanguage, code: codeBlockLines.joined(separator: "\n")))
                    codeBlockLines = []
                    codeBlockLanguage = nil
                    inCodeBlock = false
                } else {
                    // Start of code block
                    inCodeBlock = true
                    codeBlockLanguage = trimmed.count > 3 ? String(trimmed.dropFirst(3)) : nil
                }
                i += 1
                continue
            }
            
            if inCodeBlock {
                codeBlockLines.append(line)
                i += 1
                continue
            }
            
            // Empty line
            if trimmed.isEmpty {
                blocks.append(.empty)
                listIndex = 0
                i += 1
                continue
            }
            
            // Heading
            if let match = trimmed.prefixMatch(of: /^(#{1,6})\s+(.+)$/) {
                let level = match.1.count
                let text = String(match.2)
                blocks.append(.heading(level: level, text: text))
                i += 1
                continue
            }
            
            // Horizontal rule
            if trimmed.prefixMatch(of: /^(-{3,}|\*{3,}|_{3,})$/) != nil {
                blocks.append(.horizontalRule)
                i += 1
                continue
            }
            
            // Blockquote
            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    var quoteLine = lines[i].trimmingCharacters(in: .whitespaces)
                    quoteLine = String(quoteLine.dropFirst())
                    if quoteLine.hasPrefix(" ") {
                        quoteLine = String(quoteLine.dropFirst())
                    }
                    quoteLines.append(quoteLine)
                    i += 1
                }
                blocks.append(.blockquote(text: quoteLines.joined(separator: " ")))
                continue
            }
            
            // Unordered list
            if trimmed.prefixMatch(of: /^[-*+]\s+(.+)$/) != nil {
                let text = String(trimmed.dropFirst(2))
                blocks.append(.listItem(ordered: false, index: 0, text: text))
                i += 1
                continue
            }
            
            // Ordered list
            if let match = trimmed.prefixMatch(of: /^(\d+)\.\s+(.+)$/) {
                listIndex += 1
                let text = String(match.2)
                blocks.append(.listItem(ordered: true, index: listIndex, text: text))
                i += 1
                continue
            }
            
            // Regular paragraph
            blocks.append(.paragraph(text: trimmed))
            listIndex = 0
            i += 1
        }
        
        return blocks
    }
    
    // MARK: - Render Block
    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            renderHeading(level: level, text: text)
            
        case .paragraph(let text):
            styledText(text)
                .font(.system(size: 15))
                .lineSpacing(4)
            
        case .codeBlock(_, let code):
            Text(code)
                .font(.system(size: 13, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .windowBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            
        case .blockquote(let text):
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 4)
                
                styledText(text)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .italic()
            }
            .padding(.vertical, 4)
            
        case .listItem(let ordered, let index, let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if ordered {
                    Text("\(index).")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .trailing)
                } else {
                    Text("•")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .center)
                }
                styledText(text)
                    .font(.system(size: 15))
            }
            
        case .horizontalRule:
            Divider()
                .padding(.vertical, 12)
            
        case .empty:
            Spacer().frame(height: 4)
        }
    }
    
    // MARK: - Render Heading
    @ViewBuilder
    private func renderHeading(level: Int, text: String) -> some View {
        let font: Font = switch level {
        case 1: .system(size: 32, weight: .bold)
        case 2: .system(size: 26, weight: .bold)
        case 3: .system(size: 22, weight: .semibold)
        case 4: .system(size: 18, weight: .semibold)
        case 5: .system(size: 16, weight: .semibold)
        default: .system(size: 15, weight: .semibold)
        }
        
        styledText(text)
            .font(font)
            .padding(.top, level <= 2 ? 12 : 6)
            .padding(.bottom, level <= 2 ? 4 : 2)
    }
    
    // MARK: - Styled Text with Inline Markdown
    private func styledText(_ text: String) -> Text {
        // Parse all inline styles and build Text
        let segments = parseInlineMarkdown(text)
        var result = Text("")
        for segment in segments {
            result = result + segment
        }
        return result
    }
    
    private func parseInlineMarkdown(_ text: String) -> [Text] {
        guard !text.isEmpty else { return [] }
        
        var segments: [Text] = []
        var i = 0
        let chars = Array(text)
        let count = chars.count
        
        while i < count {
            // Bold + Italic (***text***)
            if i + 6 < count && chars[i] == "*" && chars[i+1] == "*" && chars[i+2] == "*" {
                if let endIdx = findClosingMarker(chars: chars, start: i + 3, marker: ["*", "*", "*"]) {
                    let content = String(chars[(i+3)..<endIdx])
                    segments.append(Text(content).bold().italic())
                    i = endIdx + 3
                    continue
                }
            }
            
            // Bold (**text**)
            if i + 4 < count && chars[i] == "*" && chars[i+1] == "*" && (i + 2 >= count || chars[i+2] != "*") {
                if let endIdx = findClosingMarker(chars: chars, start: i + 2, marker: ["*", "*"]) {
                    let content = String(chars[(i+2)..<endIdx])
                    segments.append(Text(content).bold())
                    i = endIdx + 2
                    continue
                }
            }
            
            // Strikethrough (~~text~~)
            if i + 4 < count && chars[i] == "~" && chars[i+1] == "~" {
                if let endIdx = findClosingMarker(chars: chars, start: i + 2, marker: ["~", "~"]) {
                    let content = String(chars[(i+2)..<endIdx])
                    segments.append(Text(content).strikethrough())
                    i = endIdx + 2
                    continue
                }
            }
            
            // Italic with asterisk (*text*) - but not **
            if i + 2 < count && chars[i] == "*" && (i + 1 >= count || chars[i+1] != "*") {
                if let endIdx = findClosingMarker(chars: chars, start: i + 1, marker: ["*"]) {
                    // Make sure it's not followed by another *
                    if endIdx + 1 >= count || chars[endIdx + 1] != "*" {
                        let content = String(chars[(i+1)..<endIdx])
                        if !content.isEmpty && !content.hasPrefix(" ") && !content.hasSuffix(" ") {
                            segments.append(Text(content).italic())
                            i = endIdx + 1
                            continue
                        }
                    }
                }
            }
            
            // Italic with underscore (_text_)
            if i + 2 < count && chars[i] == "_" && (i + 1 >= count || chars[i+1] != "_") {
                if let endIdx = findClosingMarker(chars: chars, start: i + 1, marker: ["_"]) {
                    let content = String(chars[(i+1)..<endIdx])
                    if !content.isEmpty && !content.hasPrefix(" ") && !content.hasSuffix(" ") {
                        segments.append(Text(content).italic())
                        i = endIdx + 1
                        continue
                    }
                }
            }
            
            // Inline code (`code`)
            if chars[i] == "`" && (i + 1 >= count || chars[i+1] != "`") {
                if let endIdx = findClosingMarker(chars: chars, start: i + 1, marker: ["`"]) {
                    let content = String(chars[(i+1)..<endIdx])
                    segments.append(Text(content)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color(nsColor: .systemPink)))
                    i = endIdx + 1
                    continue
                }
            }
            
            // Link [text](url)
            if chars[i] == "[" {
                if let closeBracket = findCharacter(chars: chars, start: i + 1, char: "]"),
                   closeBracket + 1 < count && chars[closeBracket + 1] == "(",
                   let closeParen = findCharacter(chars: chars, start: closeBracket + 2, char: ")") {
                    let linkText = String(chars[(i+1)..<closeBracket])
                    segments.append(Text(linkText)
                        .foregroundColor(.blue)
                        .underline())
                    i = closeParen + 1
                    continue
                }
            }
            
            // Regular character
            segments.append(Text(String(chars[i])))
            i += 1
        }
        
        return segments
    }
    
    private func findClosingMarker(chars: [Character], start: Int, marker: [Character]) -> Int? {
        let count = chars.count
        var i = start
        while i <= count - marker.count {
            var found = true
            for (j, m) in marker.enumerated() {
                if chars[i + j] != m {
                    found = false
                    break
                }
            }
            if found {
                return i
            }
            i += 1
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
}

#Preview {
    MarkdownView(content: """
    # Welcome to Drift
    
    This is a **beautiful** notes app with _Markdown_ support.
    
    You can also use ***bold and italic*** together!
    
    ## Features
    
    - Create and organize notes
    - Full **Markdown** support
    - Fast and _lightweight_
    - Support for `inline code`
    - And ~~strikethrough~~ text
    
    ### Code Example
    
    ```swift
    let greeting = "Hello, Drift!"
    print(greeting)
    ```
    
    > This is a blockquote with some **important** information.
    
    ---
    
    1. First item
    2. Second item
    3. Third item
    
    Visit [GitHub](https://github.com) for more info.
    """)
    .frame(width: 500, height: 700)
}
