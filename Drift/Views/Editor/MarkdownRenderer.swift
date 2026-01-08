//
//  MarkdownRenderer.swift
//  Drift
//
//  Renders Markdown content to styled SwiftUI views using Swift Markdown
//

import SwiftUI
import AppKit
import Markdown

// MARK: - Main Markdown View
struct MarkdownView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let document = try? Document(parsing: content) {
                    MarkdownRenderer(document: document).body
                } else {
                    Text("Unable to parse markdown")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .textSelection(.enabled)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Markdown AST Renderer
struct MarkdownRenderer {
    let document: Document
    
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(document.children.enumerated()), id: \.offset) { _, block in
                renderMarkdownBlock(block)
            }
        }
    }
    
    @ViewBuilder
    private func renderMarkdownBlock(_ block: Markup) -> some View {
        switch block {
        case let heading as Heading:
            renderHeading(heading)
        case let paragraph as Paragraph:
            renderParagraph(paragraph)
        case let codeBlock as CodeBlock:
            renderCodeBlock(codeBlock)
        case let blockQuote as BlockQuote:
            renderBlockQuote(blockQuote)
        case let list as UnorderedList:
            renderUnorderedList(list)
        case let list as OrderedList:
            renderOrderedList(list)
        case is ThematicBreak:
            Divider().padding(.vertical, 12)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func renderHeading(_ heading: Heading) -> some View {
        let font: Font = switch heading.level {
        case 1: .system(size: 32, weight: .bold)
        case 2: .system(size: 26, weight: .bold)
        case 3: .system(size: 22, weight: .semibold)
        case 4: .system(size: 18, weight: .semibold)
        case 5: .system(size: 16, weight: .semibold)
        default: .system(size: 15, weight: .semibold)
        }
        
        VStack(alignment: .leading) {
            renderInlineMarkup(heading)
                .font(font)
                .padding(.top, heading.level <= 2 ? 12 : 6)
                .padding(.bottom, heading.level <= 2 ? 4 : 2)
        }
    }
    
    @ViewBuilder
    private func renderParagraph(_ paragraph: Paragraph) -> some View {
        VStack(alignment: .leading) {
            renderInlineMarkup(paragraph)
                .font(.system(size: 15))
                .lineSpacing(4)
        }
    }
    
    @ViewBuilder
    private func renderCodeBlock(_ codeBlock: CodeBlock) -> some View {
        let language = codeBlock.language ?? ""
        let code = codeBlock.code
        
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
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.primary)
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
    }
    
    @ViewBuilder
    private func renderBlockQuote(_ blockQuote: BlockQuote) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.blue.opacity(0.6))
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(blockQuote.children.enumerated()), id: \.offset) { _, child in
                    renderMarkdownBlock(child)
                }
            }
            .foregroundStyle(.secondary)
            .italic()
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func renderUnorderedList(_ list: UnorderedList) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(list.children.enumerated()), id: \.offset) { _, item in
                if let listItem = item as? ListItem {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .center)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(listItem.children.enumerated()), id: \.offset) { _, child in
                                renderMarkdownBlock(child)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderOrderedList(_ list: OrderedList) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(list.children.enumerated()), id: \.offset) { index, item in
                if let listItem = item as? ListItem {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .trailing)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(listItem.children.enumerated()), id: \.offset) { _, child in
                                renderMarkdownBlock(child)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func renderInlineMarkup(_ container: Markup) -> SwiftUI.Text {
        let segments = renderInlineSegments(container)
        return segments.reduce(SwiftUI.Text("")) { $0 + $1 }
    }
    
    private func renderInlineSegments(_ container: Markup) -> [SwiftUI.Text] {
        var segments: [SwiftUI.Text] = []
        
        for child in container.children {
            switch child {
            case let text as Markdown.Text:
                segments.append(SwiftUI.Text(text.plainText))
                
            case let softBreak as SoftBreak:
                segments.append(SwiftUI.Text(" "))
                
            case let lineBreak as LineBreak:
                segments.append(SwiftUI.Text("\n"))
                
            case let strong as Strong:
                let innerSegments = renderInlineSegments(strong)
                let combined = innerSegments.reduce(SwiftUI.Text("")) { $0 + $1 }
                segments.append(combined.bold())
                
            case let emphasis as Emphasis:
                let innerSegments = renderInlineSegments(emphasis)
                let combined = innerSegments.reduce(SwiftUI.Text("")) { $0 + $1 }
                segments.append(combined.italic())
                
            case let strikethrough as Strikethrough:
                let innerSegments = renderInlineSegments(strikethrough)
                let combined = innerSegments.reduce(SwiftUI.Text("")) { $0 + $1 }
                segments.append(combined.strikethrough())
                
            case let code as InlineCode:
                segments.append(
                    SwiftUI.Text(code.code)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Color(nsColor: .systemPink))
                )
                
            case let link as Markdown.Link:
                let innerSegments = renderInlineSegments(link)
                let combined = innerSegments.reduce(SwiftUI.Text("")) { $0 + $1 }
                segments.append(
                    combined
                        .foregroundStyle(.blue)
                        .underline()
                )
                
            default:
                let innerSegments = renderInlineSegments(child)
                segments.append(contentsOf: innerSegments)
            }
        }
        
        return segments
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