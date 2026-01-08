//
//  MarkdownRenderer.swift
//  Drift
//
//  Markdown preview using swift-markdown-ui with GitHub Flavored Markdown spec
//  Theme: Drift Dark (Dracula palette)
//

import SwiftUI
import MarkdownUI

// MARK: - Drift Dark Theme Colors
/// GitHub Flavored Markdown colors inspired by GitHub's dark theme,
/// adapted with Dracula palette for visual cohesion with editor
extension Color {
    // MARK: - Primary Text Colors
    fileprivate static let driftText = Color(
        red: 0.973, green: 0.973, blue: 0.949  // #f8f8f2 - Main foreground text
    )
    fileprivate static let driftSecondaryText = Color(
        red: 0.576, green: 0.635, blue: 0.792  // #92a2ca - Secondary/muted text
    )
    fileprivate static let driftTertiaryText = Color(
        red: 0.427, green: 0.482, blue: 0.647  // #6d7ba4 - Tertiary/very muted text
    )
    
    // MARK: - Background Colors
    fileprivate static let driftBackground = Color(
        red: 0.0745, green: 0.0784, blue: 0.1098  // #13141C - Main background
    )
    fileprivate static let driftSecondaryBackground = Color(
        red: 0.11, green: 0.12, blue: 0.16  // #1c1e29 - Secondary background for code/tables
    )
    
    // MARK: - Accent Colors
    fileprivate static let driftLink = Color(
        red: 0.545, green: 0.918, blue: 0.996  // #8be9fd - Cyan for links (Dracula)
    )
    fileprivate static let driftBorder = Color(
        red: 0.267, green: 0.306, blue: 0.408  // #444d68 - Subtle borders
    )
    fileprivate static let driftDivider = Color(
        red: 0.2, green: 0.235, blue: 0.325  // #333d53 - Divider lines
    )
    
    // MARK: - Task List Colors
    fileprivate static let driftCheckbox = Color(
        red: 0.576, green: 0.635, blue: 0.792  // #92a2ca - Checkbox icon
    )
    fileprivate static let driftCheckboxBackground = Color(
        red: 0.2, green: 0.235, blue: 0.325  // #333d53 - Checkbox background
    )
}

// MARK: - GitHub Flavored Markdown Theme
/// Implements GFM spec 0.29 (https://github.github.com/gfm/)
/// Based on swift-markdown-ui's GitHub theme but using Drift Dark colors
/// Reference: https://github.com/gonzalezreal/swift-markdown-ui/blob/main/Sources/MarkdownUI/Theme/Theme%2BGitHub.swift
extension Theme {
    static let driftDark = Theme()
        // MARK: - Text Styles
        .text {
            ForegroundColor(.driftText)
            BackgroundColor(.driftBackground)
            FontSize(16)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
            BackgroundColor(.driftSecondaryBackground)
        }
        .strong {
            FontWeight(.semibold)
        }
        .link {
            ForegroundColor(.driftLink)
        }
        
        // MARK: - Headings (GFM Section 4.2)
        /// H1 and H2 get visual dividers like GitHub
        .heading1 { configuration in
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .relativePadding(.bottom, length: .em(0.3))
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(2))
                    }
                Divider().overlay(Color.driftDivider)
            }
        }
        .heading2 { configuration in
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .relativePadding(.bottom, length: .em(0.3))
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 24, bottom: 16)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(1.5))
                    }
                Divider().overlay(Color.driftDivider)
            }
        }
        .heading3 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.25))
                }
        }
        .heading4 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.semibold)
                }
        }
        .heading5 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(0.875))
                }
        }
        .heading6 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(0.85))
                    ForegroundColor(.driftTertiaryText)
                }
        }
        
        // MARK: - Paragraph (GFM Section 4.8)
        .paragraph { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .relativeLineSpacing(.em(0.25))
                .markdownMargin(top: 0, bottom: 16)
        }
        
        // MARK: - Block Quotes (GFM Section 5.1)
        .blockquote { configuration in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.driftBorder)
                    .relativeFrame(width: .em(0.2))
                configuration.label
                    .markdownTextStyle { ForegroundColor(.driftSecondaryText) }
                    .relativePadding(.horizontal, length: .em(1))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        
        // MARK: - Code Blocks (GFM Sections 4.4 & 4.5)
        .codeBlock { configuration in
            ScrollView(.horizontal) {
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.225))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding(16)
            }
            .background(Color.driftSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .markdownMargin(top: 0, bottom: 16)
        }
        
        // MARK: - List Items (GFM Section 5.2)
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.25))
        }
        
        // MARK: - Task List Items (GFM Section 5.3 - Extension)
        .taskListMarker { configuration in
            Image(systemName: configuration.isCompleted ? "checkmark.square.fill" : "square")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.driftCheckbox, Color.driftCheckboxBackground)
                .imageScale(.small)
                .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
        }
        
        // MARK: - Tables (GFM Section 4.10 - Extension)
        .table { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .markdownTableBorderStyle(.init(color: .driftBorder))
                .markdownTableBackgroundStyle(
                    .alternatingRows(Color.driftBackground, Color.driftSecondaryBackground)
                )
                .markdownMargin(top: 0, bottom: 16)
        }
        .tableCell { configuration in
            configuration.label
                .markdownTextStyle {
                    if configuration.row == 0 {
                        FontWeight(.semibold)
                    }
                    BackgroundColor(nil)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 6)
                .padding(.horizontal, 13)
                .relativeLineSpacing(.em(0.25))
        }
        
        // MARK: - Thematic Break (GFM Section 4.1)
        .thematicBreak {
            Divider()
                .relativeFrame(height: .em(0.25))
                .overlay(Color.driftBorder)
                .markdownMargin(top: 24, bottom: 24)
        }
}

// MARK: - Main Markdown Renderer
/// Renders GitHub Flavored Markdown with Drift Dark theme
/// Theme implementation based on gonzalezreal/swift-markdown-ui GitHub theme
struct MarkdownView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            Markdown(content)
                .markdownTheme(.driftDark)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.driftBackground)
    }
}

#Preview {
    MarkdownView(content: """
    # Drift Dark Theme
    
    Professional GitHub Flavored Markdown rendering with Drift Dark colors.
    
    ## Text Styling
    
    Use **bold**, _italic_, and ***bold italic*** text.
    ~~Strikethrough~~ is also supported.
    
    `Inline code` uses a monospaced font with contrast background.
    
    ## Headings Hierarchy
    
    ### Level 3 Heading
    
    #### Level 4 Heading
    
    ##### Level 5 Heading
    
    ###### Level 6 Heading
    
    ## Code Blocks
    
    ```swift
    struct Note {
        var title: String
        var content: String
        var createdAt: Date
    }
    ```
    
    ## Lists & Task Items
    
    - First bullet point
    - Second point with **bold** text
      - Nested item
    
    1. Numbered list item
    2. Another numbered item
    
    - [ ] Incomplete task
    - [x] Completed task
    
    ## Block Quotes
    
    > This is a blockquote with a visual left border,
    > just like on GitHub. Perfect for highlighting
    > important information.
    
    ## Thematic Break
    
    Sections are separated by horizontal rules:
    
    ---
    
    ## Links
    
    [Visit GitHub](https://github.com) for more information.
    """)
    .frame(width: 600, height: 1000)
}