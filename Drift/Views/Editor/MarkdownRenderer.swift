//
//  MarkdownRenderer.swift
//  Drift
//
//  Lightweight markdown preview view
//

import SwiftUI
import AppKit

// MARK: - Main Markdown View
struct MarkdownView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                let lines = content.components(separatedBy: "\n")
                let elements = processMarkdownLines(lines)
                ForEach(Array(elements.enumerated()), id: \.offset) { _, element in
                    element
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .textSelection(.enabled)
        }
        .background(Color(red: 0.0745, green: 0.0784, blue: 0.1098))
    }
    
    private func processMarkdownLines(_ lines: [String]) -> [AnyView] {
        var views: [AnyView] = []
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            
            // Headings
            if line.hasPrefix("# ") {
                views.append(AnyView(
                    renderText(String(line.dropFirst(2)))
                        .font(.system(size: 32, weight: .bold))
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                ))
            } else if line.hasPrefix("## ") {
                views.append(AnyView(
                    renderText(String(line.dropFirst(3)))
                        .font(.system(size: 26, weight: .bold))
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                ))
            } else if line.hasPrefix("### ") {
                views.append(AnyView(
                    renderText(String(line.dropFirst(4)))
                        .font(.system(size: 22, weight: .semibold))
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                ))
            } else if line.hasPrefix("#### ") {
                views.append(AnyView(
                    renderText(String(line.dropFirst(5)))
                        .font(.system(size: 18, weight: .semibold))
                ))
            } else if line.hasPrefix("##### ") {
                views.append(AnyView(
                    renderText(String(line.dropFirst(6)))
                        .font(.system(size: 16, weight: .semibold))
                ))
            }
            // Code blocks
            else if line.hasPrefix("```") {
                let language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                views.append(AnyView(
                    VStack(alignment: .leading, spacing: 0) {
                        if !language.isEmpty {
                            Text(language.lowercased())
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: .separatorColor).opacity(0.5))
                        }
                        ScrollView(.horizontal) {
                            Text(codeLines.joined(separator: "\n"))
                                .font(.system(size: 13, design: .monospaced))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                ))
            }
            // Blockquotes
            else if line.hasPrefix("> ") {
                views.append(AnyView(
                    HStack(alignment: .top, spacing: 12) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 4)
                        renderText(String(line.dropFirst(2)))
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    .padding(.vertical, 4)
                ))
            }
            // Unordered lists
            else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                views.append(AnyView(
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .center)
                        renderText(String(line.dropFirst(2)))
                    }
                ))
            }
            // Ordered lists
            else if let match = line.range(of: "^\\d+\\. ", options: .regularExpression) {
                let prefix = String(line[match])
                let rest = String(line[match.upperBound...])
                views.append(AnyView(
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(prefix.trimmingCharacters(in: .whitespaces))
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .trailing)
                        renderText(rest)
                    }
                ))
            }
            // Horizontal rule
            else if line.trimmingCharacters(in: .whitespaces) == "---" || line.trimmingCharacters(in: .whitespaces) == "***" {
                views.append(AnyView(
                    Divider()
                        .padding(.vertical, 12)
                ))
            }
            // Regular paragraphs
            else if !line.isEmpty && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                views.append(AnyView(
                    renderText(line)
                        .font(.system(size: 15))
                        .lineSpacing(4)
                ))
            }
            
            i += 1
        }
        
        return views
    }
    
    private func renderText(_ text: String) -> SwiftUI.Text {
        var result = SwiftUI.Text("")
        var currentText = ""
        var i = text.startIndex
        
        while i < text.endIndex {
            // Bold **text**
            if text[i] == "*" && text.index(after: i) < text.endIndex && text[text.index(after: i)] == "*" {
                if !currentText.isEmpty {
                    result = result + SwiftUI.Text(currentText)
                    currentText = ""
                }
                i = text.index(i, offsetBy: 2)
                var boldText = ""
                while i < text.endIndex {
                    if text[i] == "*" && text.index(after: i) < text.endIndex && text[text.index(after: i)] == "*" {
                        result = result + SwiftUI.Text(boldText).bold()
                        i = text.index(i, offsetBy: 2)
                        break
                    }
                    boldText.append(text[i])
                    i = text.index(after: i)
                }
                continue
            }
            
            // Italic _text_
            if text[i] == "_" {
                if !currentText.isEmpty {
                    result = result + SwiftUI.Text(currentText)
                    currentText = ""
                }
                i = text.index(after: i)
                var italicText = ""
                while i < text.endIndex {
                    if text[i] == "_" {
                        result = result + SwiftUI.Text(italicText).italic()
                        i = text.index(after: i)
                        break
                    }
                    italicText.append(text[i])
                    i = text.index(after: i)
                }
                continue
            }
            
            // Strikethrough ~~text~~
            if text[i] == "~" && text.index(after: i) < text.endIndex && text[text.index(after: i)] == "~" {
                if !currentText.isEmpty {
                    result = result + SwiftUI.Text(currentText)
                    currentText = ""
                }
                i = text.index(i, offsetBy: 2)
                var strikeText = ""
                while i < text.endIndex {
                    if text[i] == "~" && text.index(after: i) < text.endIndex && text[text.index(after: i)] == "~" {
                        result = result + SwiftUI.Text(strikeText).strikethrough()
                        i = text.index(i, offsetBy: 2)
                        break
                    }
                    strikeText.append(text[i])
                    i = text.index(after: i)
                }
                continue
            }
            
            // Inline code `text`
            if text[i] == "`" {
                if !currentText.isEmpty {
                    result = result + SwiftUI.Text(currentText)
                    currentText = ""
                }
                i = text.index(after: i)
                var codeText = ""
                while i < text.endIndex {
                    if text[i] == "`" {
                        result = result + SwiftUI.Text(codeText)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Color(nsColor: .systemPink))
                        i = text.index(after: i)
                        break
                    }
                    codeText.append(text[i])
                    i = text.index(after: i)
                }
                continue
            }
            
            currentText.append(text[i])
            i = text.index(after: i)
        }
        
        if !currentText.isEmpty {
            result = result + SwiftUI.Text(currentText)
        }
        
        return result
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
    """)
    .frame(width: 500, height: 700)
}