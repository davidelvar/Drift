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
        
        // Inline code: backtick-enclosed text
        // Matches: `code text`
        let stringRegex = Regex {
            /`[^`]+`/
        }
        
        // Code blocks: triple backtick fences
        // Matches: ```
        let characterRegex = Regex {
            /```/
        }
        
        // Links: [text](url) pattern
        // Matches: [link text](https://example.com)
        let identifierRegex = Regex {
            /\[[^\]]*\]\([^\)]*\)/
        }
        
        // Markdown operators: special characters for formatting
        // Matches: **, __, *, _, ~~, #, -, +, >
        let operatorRegex = Regex {
            ChoiceOf {
                "\\*\\*"   // bold **
                "__"       // bold __
                "~~"       // strikethrough  
                /[*_#\-+>]/ // individual operators
            }
        }
        
        // Numbers: for lists
        let numberRegex = Regex {
            /\d+/
        }
        
        return LanguageConfiguration(
            name: "Markdown",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: false,
            stringRegex: stringRegex,               // Inline code → strings (green)
            characterRegex: characterRegex,         // Code fences → characters (yellow)
            numberRegex: numberRegex,               // Numbers for lists
            singleLineComment: nil,
            nestedComment: (open: "<!--", close: "-->"),
            identifierRegex: identifierRegex,       // Links → identifiers (cyan)
            operatorRegex: operatorRegex,           // Markdown operators (orange)
            reservedIdentifiers: [],
            reservedOperators: [
                "**", "__", "*", "_", "`", "~~", "#", "-", "+", ">"
            ],
            languageService: languageService
        )
    }
}
