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
        
        // Headings: # ## ### etc
        // Matches: # Heading, ## Subheading
        let identifierRegex = Regex {
            ChoiceOf {
                /#{1,6}\s+[^\n]*?(?=\n|$)/  // Headings
                /\[[^\]]*\]\([^\)]*\)/       // Links [text](url)
            }
        }
        
        // Inline code: backtick-enclosed text
        // Matches: `code text`
        let stringRegex = Regex {
            /`[^`]+`/
        }
        
        // Bold text: **text** or __text__
        let characterRegex = Regex {
            ChoiceOf {
                /\*\*[^*]+\*\*/      // **bold**
                /__[^_]+__/          // __bold__
            }
        }
        
        // Markdown operators: operators and special formatting
        let operatorRegex = Regex {
            ChoiceOf {
                /```/                // Code fence
                />\s/                // Blockquote
                /[-*+]\s/            // List markers
                /\*[^*]+\*/          // *italic*
                /_[^_]+_/            // _italic_
                /~~[^~]+~~/          // ~~strikethrough~~
            }
        }
        
        // Numbers: for numbered lists
        let numberRegex = Regex {
            /\d+\./
        }
        
        return LanguageConfiguration(
            name: "Markdown",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: false,
            stringRegex: stringRegex,               // Inline code → cyan
            characterRegex: characterRegex,         // Bold → magenta
            numberRegex: numberRegex,               // List numbers → magenta
            singleLineComment: nil,
            nestedComment: (open: "<!--", close: "-->"),
            identifierRegex: identifierRegex,       // Headings & links → cyan
            operatorRegex: operatorRegex,           // Operators → magenta
            reservedIdentifiers: [],
            reservedOperators: [
                "**", "__", "*", "_", "`", "~~", "#", "-", "+", ">"
            ],
            languageService: languageService
        )
    }
}
