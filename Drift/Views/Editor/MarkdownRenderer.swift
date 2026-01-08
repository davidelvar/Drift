//
//  MarkdownRenderer.swift
//  Drift
//
//  Markdown preview using swift-markdown-ui with Dracula-GitHub theme
//

import SwiftUI
import MarkdownUI

// MARK: - Dracula Theme Colors
struct DraculaColors {
    static let background = Color(red: 0.0745, green: 0.0784, blue: 0.1098)      // #13141C
    static let foreground = Color(red: 0.973, green: 0.973, blue: 0.949)         // #f8f8f2
    static let cyan = Color(red: 0.545, green: 0.918, blue: 0.996)               // #8be9fd
    static let magenta = Color(red: 0.957, green: 0.357, blue: 0.812)            // #f55bcf
    static let orange = Color(red: 1.0, green: 0.635, blue: 0.408)               // #ffaa66
    static let green = Color(red: 0.502, green: 0.851, blue: 0.420)              // #80dd54
    static let red = Color(red: 1.0, green: 0.400, blue: 0.400)                  // #ff6464
    static let gray = Color(red: 0.388, green: 0.447, blue: 0.643)               // #6372a4
    static let comment = Color(red: 0.388, green: 0.447, blue: 0.643)            // #6372a4
    static let codeBackground = Color(red: 0.11, green: 0.12, blue: 0.16)        // darker background for code
}

// MARK: - Custom Dracula GitHub Theme
extension Theme {
    static let draculaGitHub = Theme()
        // Headings
        .heading1 { configuration in
            configuration.label
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(DraculaColors.cyan)
                .markdownMargin(top: 24, bottom: 16)
        }
        .heading2 { configuration in
            configuration.label
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(DraculaColors.cyan)
                .markdownMargin(top: 20, bottom: 12)
        }
        .heading3 { configuration in
            configuration.label
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DraculaColors.cyan)
                .markdownMargin(top: 16, bottom: 10)
        }
        .heading4 { configuration in
            configuration.label
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(DraculaColors.cyan)
                .markdownMargin(top: 12, bottom: 8)
        }
        .heading5 { configuration in
            configuration.label
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DraculaColors.cyan)
                .markdownMargin(top: 10, bottom: 6)
        }
        .heading6 { configuration in
            configuration.label
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DraculaColors.cyan)
                .markdownMargin(top: 8, bottom: 4)
        }
        // Paragraph
        .paragraph { configuration in
            configuration.label
                .font(.system(size: 16))
                .foregroundColor(DraculaColors.foreground)
                .markdownMargin(top: 0, bottom: 12)
                .lineSpacing(3)
        }
        // Inline code
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.9))
            ForegroundColor(DraculaColors.cyan)
            BackgroundColor(DraculaColors.codeBackground)
        }
        // Code blocks
        .codeBlock { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.225))
                .padding(12)
                .background(DraculaColors.codeBackground)
                .cornerRadius(6)
                .markdownMargin(top: 0, bottom: 16)
        }
        // Links
        .link {
            ForegroundColor(DraculaColors.cyan)
        }
        // Strong (bold)
        .strong {
            FontWeight(.bold)
            ForegroundColor(DraculaColors.magenta)
        }
        // Emphasis (italic)
        .emphasis {
            FontWeight(.semibold)
            ForegroundColor(DraculaColors.orange)
        }
        // Strikethrough
        .strikethrough {
            ForegroundColor(DraculaColors.red)
        }
        // Blockquotes
        .blockquote { configuration in
            configuration.label
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(DraculaColors.gray)
                        .frame(width: 4)
                }
                .background(Color(red: 0.15, green: 0.16, blue: 0.22))
                .markdownMargin(top: 0, bottom: 16)
        }
        // List items
        .listItem { configuration in
            configuration.label
                .foregroundColor(DraculaColors.foreground)
                .markdownMargin(top: 0, bottom: 8)
        }
        // Bulleted list markers
        .bulletedListMarker { marker in
            Text(marker)
                .foregroundColor(DraculaColors.magenta)
        }
        // Numbered list markers
        .numberedListMarker { marker in
            Text(marker)
                .foregroundColor(DraculaColors.magenta)
        }
        // Thematic break (horizontal rule)
        .thematicBreak {
            Divider()
                .frame(height: 1)
                .background(DraculaColors.gray)
        }
}

// MARK: - Main Markdown View
struct MarkdownView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            Markdown(content)
                .markdownTheme(.draculaGitHub)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DraculaColors.background)
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