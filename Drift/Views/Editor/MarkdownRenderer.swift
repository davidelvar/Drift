//
//  MarkdownRenderer.swift
//  Drift
//
//  Markdown preview using swift-markdown-ui with GitHub Flavored Markdown spec
//  Theme: Drift Dark (Dracula palette)
//

import SwiftUI
import MarkdownUI

// MARK: - GitHub Flavored Markdown Colors (Drift Dark Theme)
struct DriftDarkColors {
    // Core colors matching Dracula palette
    static let background = Color(red: 0.0745, green: 0.0784, blue: 0.1098)      // #13141C - Main background
    static let foreground = Color(red: 0.973, green: 0.973, blue: 0.949)         // #f8f8f2 - Main text
    static let cyan = Color(red: 0.545, green: 0.918, blue: 0.996)               // #8be9fd - Headings, links, code
    static let magenta = Color(red: 0.957, green: 0.357, blue: 0.812)            // #f55bcf - Strong emphasis
    static let orange = Color(red: 1.0, green: 0.635, blue: 0.408)               // #ffaa66 - Emphasis
    static let green = Color(red: 0.502, green: 0.851, blue: 0.420)              // #80dd54 - Success/additions
    static let red = Color(red: 1.0, green: 0.400, blue: 0.400)                  // #ff6464 - Strikethrough/deletions
    static let gray = Color(red: 0.388, green: 0.447, blue: 0.643)               // #6372a4 - Muted/borders
    static let comment = Color(red: 0.388, green: 0.447, blue: 0.643)            // #6372a4 - Comments
    static let codeBackground = Color(red: 0.11, green: 0.12, blue: 0.16)        // Darker background for code blocks
    
    // GFM-specific colors
    static let tableBorder = Color(red: 0.267, green: 0.306, blue: 0.408)        // #444d68 - Table borders (lighter gray)
    static let tableRowAlt = Color(red: 0.13, green: 0.14, blue: 0.19)           // #212338 - Alternating rows
}

// MARK: - GitHub Flavored Markdown Theme
/// Implements GFM spec 0.29 (https://github.github.com/gfm/)
/// Based on GitHub's default light theme but rendered in Drift Dark colors
extension Theme {
    static let driftDark = Theme()
        // MARK: - Headings (GFM Section 4.2)
        .heading1 { configuration in
            configuration.label
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(DriftDarkColors.cyan)
                .markdownMargin(top: 24, bottom: 16)
        }
        .heading2 { configuration in
            configuration.label
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(DriftDarkColors.cyan)
                .markdownMargin(top: 20, bottom: 12)
        }
        .heading3 { configuration in
            configuration.label
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DriftDarkColors.cyan)
                .markdownMargin(top: 16, bottom: 10)
        }
        .heading4 { configuration in
            configuration.label
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(DriftDarkColors.cyan)
                .markdownMargin(top: 12, bottom: 8)
        }
        .heading5 { configuration in
            configuration.label
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DriftDarkColors.cyan)
                .markdownMargin(top: 10, bottom: 6)
        }
        .heading6 { configuration in
            configuration.label
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DriftDarkColors.cyan)
                .markdownMargin(top: 8, bottom: 4)
        }
        
        // MARK: - Paragraph (GFM Section 4.8)
        .paragraph { configuration in
            configuration.label
                .font(.system(size: 16))
                .foregroundColor(DriftDarkColors.foreground)
                .markdownMargin(top: 0, bottom: 12)
                .lineSpacing(3)
        }
        
        // MARK: - Code Spans (GFM Section 6.3)
        /// Inline code with monospace font and contrasting background
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.9))
            ForegroundColor(DriftDarkColors.cyan)
            BackgroundColor(DriftDarkColors.codeBackground)
        }
        
        // MARK: - Code Blocks (GFM Section 4.4 & 4.5)
        /// Fenced and indented code blocks with language support
        .codeBlock { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.225))
                .padding(12)
                .background(DriftDarkColors.codeBackground)
                .cornerRadius(6)
                .markdownMargin(top: 0, bottom: 16)
        }
        
        // MARK: - Links (GFM Section 6.6)
        /// Inline and reference links
        .link {
            ForegroundColor(DriftDarkColors.cyan)
        }
        
        // MARK: - Emphasis (GFM Section 6.4)
        /// Single * or _ for emphasis
        .emphasis {
            FontWeight(.semibold)
            ForegroundColor(DriftDarkColors.orange)
        }
        
        // MARK: - Strong Emphasis (GFM Section 6.4)
        /// Double ** or __ for strong emphasis
        .strong {
            FontWeight(.bold)
            ForegroundColor(DriftDarkColors.magenta)
        }
        
        // MARK: - Strikethrough (GFM Section 6.5 - Extension)
        /// GFM extension: ~~text~~ for strikethrough
        .strikethrough {
            ForegroundColor(DriftDarkColors.red)
        }
        
        // MARK: - Block Quotes (GFM Section 5.1)
        /// Block quotes with left border and alternate background
        .blockquote { configuration in
            configuration.label
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(DriftDarkColors.gray)
                        .frame(width: 4)
                }
                .background(Color(red: 0.15, green: 0.16, blue: 0.22))
                .markdownMargin(top: 0, bottom: 16)
        }
        
        // MARK: - List Items (GFM Section 5.2)
        /// Bullet lists (-/*) and ordered lists (1.)
        .listItem { configuration in
            configuration.label
                .foregroundColor(DriftDarkColors.foreground)
                .markdownMargin(top: 0, bottom: 8)
        }
        
        // MARK: - Thematic Breaks (GFM Section 4.1)
        /// Horizontal rules (---, ***, ___)
        .thematicBreak {
            Divider()
                .frame(height: 1)
                .background(DriftDarkColors.gray)
                .markdownMargin(top: 16, bottom: 16)
        }
}

// MARK: - Main Markdown Renderer
/// Renders GitHub Flavored Markdown with Drift Dark theme
struct MarkdownView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            Markdown(content)
                .markdownTheme(.driftDark)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DriftDarkColors.background)
    }
}

#Preview {
    MarkdownView(content: """
    # GitHub Flavored Markdown with Drift Dark Theme
    
    This preview demonstrates all GFM features supported by the Drift Dark theme.
    
    ## 1. Headings (GFM Section 4.2)
    
    Headings 1-6 are supported with consistent styling and proper spacing.
    
    ### Subheading Example
    
    Text after headings flows naturally.
    
    ## 2. Text Formatting
    
    You can use **bold** text, _italic_ text, and ***bold italic***.
    
    You can also use ~~strikethrough~~ text (GFM Extension).
    
    ## 3. Lists
    
    Bullet lists:
    - First item
    - Second item
    - Third item nested:
      - Nested item 1
      - Nested item 2
    
    Numbered lists:
    1. First numbered item
    2. Second numbered item
    3. Third numbered item
    
    ## 4. Code
    
    Inline code uses `monospace font` for syntax.
    
    Code blocks support syntax highlighting:
    
    ```swift
    func greet(name: String) -> String {
        return "Hello, \\(name)!"
    }
    ```
    
    ## 5. Links and References
    
    [Inline link to GitHub](https://github.com)
    
    [Reference style link][1]
    
    [1]: https://github.com
    
    ## 6. Blockquotes
    
    > This is a blockquote.
    > It can span multiple lines.
    >
    > And contain **multiple paragraphs**.
    
    ## 7. Thematic Breaks
    
    Horizontal rules separate sections:
    
    ---
    
    ## 8. GFM Extensions
    
    ### Strikethrough (GFM Extension)
    
    ~~This text is struck through~~
    
    ### Autolinks (GFM Extension)
    
    You can use URLs like https://github.com directly!
    
    And email addresses like user@example.com work too!
    
    ## Summary
    
    The Drift Dark theme implements GitHub Flavored Markdown spec 0.29
    with comprehensive support for all common markdown elements and GFM extensions.
    """)
    .frame(width: 600, height: 900)
}