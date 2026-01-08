//
//  MarkdownConfiguration.swift
//  Drift
//
//  Language configuration for GitHub Flavored Markdown
//

import Foundation
import RegexBuilder
import LanguageSupport


extension LanguageConfiguration {
    
    /// Language configuration for Markdown (GitHub Flavored Markdown)
    ///
    public static func markdown(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        
        // MARK: - Regex Patterns using standard regex strings
        
        // Inline code: `code`
        let inlineCodeRegex = Regex {
            "`[^`]+`"
        }
        
        // Code blocks: ```language ... ```
        let codeBlockRegex = Regex {
            "```[a-z]*\\n([^`]*\\n)*```"
        }
        
        // Links: [text](url) or [text](url "title")
        let linkRegex = Regex {
            "\\[[^\\]]+\\]\\([^)]+\\)"
        }
        
        // Operator regex for markdown formatting markers
        let operatorRegex = Regex {
            "\\*{1,2}|_{1,2}|`|~{2}|#|-|\\+|\\d+\\."
        }
        
        // Number regex for code block markers and list numbers
        let numberRegex = Regex {
            "\\d+"
        }
        
        return LanguageConfiguration(
            name: "Markdown",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: false,
            stringRegex: inlineCodeRegex,           // Inline code highlighted as strings
            characterRegex: codeBlockRegex,         // Code blocks highlighted as characters
            numberRegex: numberRegex,               // List numbers
            singleLineComment: nil,
            nestedComment: (open: "<!--", close: "-->"),
            identifierRegex: linkRegex,             // Links highlighted as identifiers
            operatorRegex: operatorRegex,           // Markdown syntax operators
            reservedIdentifiers: [
                // Markdown special patterns that should be highlighted
                "**", "__", "*", "_", "`", "~~", "#", "-", "+", ">"
            ],
            reservedOperators: [
                "**", "__", "*", "_", "`", "~~", "#", "-", "+", ">"
            ],
            languageService: languageService
        )
    }
}
