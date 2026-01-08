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
        
        // MARK: - Regex Patterns for Markdown
        
        // Headings: # ## ### etc - capture as identifiers for prominent coloring
        // Matches: # Heading, ## Subheading, etc.
        let identifierRegex = Regex {
            ChoiceOf {
                /^#{1,6}\s+[^\n]*$/  // Headings
                /\[[^\]]*\]\([^\)]*\)/ // Links [text](url)
            }
        }
        
        // Inline code: backtick-enclosed text
        // Matches: `code text`
        let stringRegex = Regex {
            /`[^`]+`/
        }
        
        // Bold text: **text** or __text__
        // Matches bold formatting
        let characterRegex = Regex {
            ChoiceOf {
                /\*\*[^*]+\*\*/      // **bold**
                /__[^_]+__/          // __bold__
            }
        }
        
        // Markdown operators: list markers, blockquotes, code fences, etc
        // Matches: -, *, +, >, ```, etc
        let operatorRegex = Regex {
            ChoiceOf {
                /```/                // Code fence
                /^>\s+/              // Blockquote
                /^[-*+]\s+/          // List markers at line start
                /\*[^*]+\*/          // *italic*
                /_[^_]+_/            // _italic_
                /~~[^~]+~~/          // ~~strikethrough~~
            }
        }
        
        // Numbers: for numbered lists
        let numberRegex = Regex {
            /^\d+\./
        }
        
        return LanguageConfiguration(
            name: "Markdown",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: false,
            stringRegex: stringRegex,               // Inline code → cyan
            characterRegex: characterRegex,         // Bold → yellow
            numberRegex: numberRegex,               // List numbers → yellow
            singleLineComment: nil,
            nestedComment: (open: "<!--", close: "-->"),
            identifierRegex: identifierRegex,       // Headings & links → cyan
            operatorRegex: operatorRegex,           // Operators → yellow
            reservedIdentifiers: [],
            reservedOperators: [
                "**", "__", "*", "_", "`", "~~", "#", "-", "+", ">"
            ],
            languageService: languageService
        )
    }
}
