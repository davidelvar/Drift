//
//  LanguageSyntaxHighlighter.swift
//  Drift
//
//  Syntax highlighting for code blocks in multiple programming languages
//  Uses Splash for comprehensive language support
//

import Foundation
import AppKit
import Splash

// MARK: - Splash Compatibility Types (Placeholders for future integration)
typealias SyntaxHighlighter = Any  // Placeholder for Splash SyntaxHighlighter

struct Dracula {
    // Placeholder for Splash Dracula theme
    // Pattern-based highlighting handles all colors for now
}

struct HtmlFormat {
    // Placeholder for Splash HtmlFormat
}

// MARK: - Language Support Enum
enum SourceLanguage: String, CaseIterable {
    case swift
    case python
    case javascript
    case typescript
    case rust
    case go
    case java
    case c
    case cpp = "c++"
    case csharp = "c#"
    case ruby
    case php
    case shell
    case bash
    case sql
    case yaml
    case json
    case kotlin
    case groovy
    case xml
    
    /// Get display name for language
    var displayName: String {
        switch self {
        case .cpp: return "C++"
        case .csharp: return "C#"
        default: return self.rawValue.capitalized
        }
    }
    
    /// Detect language from code block fence identifier
    static func detect(from identifier: String) -> SourceLanguage? {
        let normalized = identifier.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Exact matches
        if let language = SourceLanguage(rawValue: normalized) {
            return language
        }
        
        // Aliases
        switch normalized {
        case "ts": return .typescript
        case "sh": return .shell
        case "yml": return .yaml
        case "js": return .javascript
        case "cs": return .csharp
        case "rb": return .ruby
        default: return nil
        }
    }
}

// MARK: - Language Syntax Highlighter
@MainActor
final class LanguageSyntaxHighlighter {
    
    // MARK: - Cached Highlighters (for future Splash integration)
    private static var splashHighlighters: [SourceLanguage: Any] = [:]
    
    /// Highlight a code block with specified language
    /// - Parameters:
    ///   - code: The source code to highlight
    ///   - language: The programming language
    ///   - storage: The NSTextStorage to apply highlights to
    ///   - baseOffset: The character offset in the full text (default: 0)
    static func highlight(
        code: String,
        language: SourceLanguage,
        in storage: NSTextStorage,
        baseOffset: Int = 0
    ) {
        switch language {
        case .swift:
            highlightSwift(code, in: storage, baseOffset: baseOffset)
        case .python:
            highlightPython(code, in: storage, baseOffset: baseOffset)
        case .javascript, .typescript:
            highlightJavaScript(code, in: storage, baseOffset: baseOffset)
        case .rust:
            highlightRust(code, in: storage, baseOffset: baseOffset)
        case .go:
            highlightGo(code, in: storage, baseOffset: baseOffset)
        case .java:
            highlightJava(code, in: storage, baseOffset: baseOffset)
        case .c:
            highlightC(code, in: storage, baseOffset: baseOffset)
        case .cpp:
            highlightCpp(code, in: storage, baseOffset: baseOffset)
        case .csharp:
            highlightCSharp(code, in: storage, baseOffset: baseOffset)
        case .ruby:
            highlightRuby(code, in: storage, baseOffset: baseOffset)
        case .php:
            highlightPHP(code, in: storage, baseOffset: baseOffset)
        case .shell, .bash:
            highlightShell(code, in: storage, baseOffset: baseOffset)
        case .sql:
            highlightSQL(code, in: storage, baseOffset: baseOffset)
        case .yaml:
            highlightYAML(code, in: storage, baseOffset: baseOffset)
        case .json:
            highlightJSON(code, in: storage, baseOffset: baseOffset)
        case .kotlin:
            highlightKotlin(code, in: storage, baseOffset: baseOffset)
        case .groovy:
            highlightGroovy(code, in: storage, baseOffset: baseOffset)
        case .xml:
            highlightXML(code, in: storage, baseOffset: baseOffset)
        }
    }
    
    /// Highlight with Splash if available for the language
    /// Note: This is a placeholder for future Splash integration.
    /// Currently uses pattern-based highlighting instead.
    static func highlightWithSplash(
        code: String,
        language: SourceLanguage,
        in storage: NSTextStorage,
        baseOffset: Int = 0
    ) {
        // For now, delegate to pattern-based highlighting
        // Future: integrate full Splash when library is available
        highlight(code: code, language: language, in: storage, baseOffset: baseOffset)
    }
    
    // MARK: - Language-Specific Highlighters
    
    private static func highlightSwift(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(func|class|struct|enum|protocol|var|let|if|else|for|while|switch|case|default|return|import|extension|private|public|internal|static|mutating)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            ("/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Type names (capitalized)
            ("\\b[A-Z][a-zA-Z0-9]*\\b", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightPython(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(def|class|if|else|elif|for|while|return|import|from|as|try|except|finally|with|lambda|pass|break|continue|and|or|not|in|is|True|False|None)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals (single and double quoted)
            ("\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("#.*", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Built-ins
            ("\\b(len|range|print|str|int|list|dict|set|enumerate)\\b", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightJavaScript(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(function|const|let|var|if|else|for|while|switch|case|return|import|export|class|extends|async|await|try|catch|finally|throw|new|this|typeof|instanceof|true|false|null|undefined)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals (single, double, and template)
            ("\"[^\"]*\"|'[^']*'|`[^`]*`", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Methods/properties
            ("\\.[a-zA-Z_][a-zA-Z0-9_]*", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightRust(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(fn|let|mut|const|static|struct|enum|trait|impl|pub|crate|use|mod|match|if|else|loop|while|for|return|unsafe|async|await|as|where|type|macro|println|format)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers and lifetime
            ("\\b\\d+\\b|'[a-zA-Z_]\\w*", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Macros
            ("\\w+!", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightGo(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(func|package|import|const|var|type|struct|interface|if|else|for|switch|case|return|defer|go|select|chan|range|break|continue|fallthrough|map)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"|`[^`]*`", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Built-in functions
            ("\\b(fmt|println|make|len|cap|append|copy|delete|complex|real|imag|panic|recover|close|new)\\b", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightJava(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(class|interface|extends|implements|public|private|protected|static|final|abstract|native|synchronized|volatile|transient|enum|package|import|if|else|for|while|do|switch|case|break|continue|return|try|catch|finally|throw|throws|new|this|super|instanceof|void|boolean|byte|char|short|int|long|float|double|true|false|null)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Type names (capitalized)
            ("\\b[A-Z][a-zA-Z0-9]*\\b", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightC(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords and types
            ("\\b(int|char|void|float|double|struct|union|enum|typedef|unsigned|signed|const|volatile|extern|static|register|auto|inline|if|else|for|while|do|switch|case|break|continue|return|goto|sizeof)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Preprocessor
            ("#[a-zA-Z]+.*", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightCpp(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        // Similar to C but with C++ keywords
        let patterns: [(pattern: String, color: NSColor)] = [
            // C++ keywords
            ("\\b(class|struct|namespace|template|public|private|protected|virtual|override|const|volatile|explicit|inline|nullptr|auto|decltype|constexpr|final|if|else|for|while|do|switch|case|break|continue|return|try|catch|throw|new|delete|this|operator|friend|using|include|define)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Preprocessor
            ("#[a-zA-Z]+.*", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightCSharp(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(class|struct|interface|namespace|using|public|private|protected|internal|static|abstract|virtual|override|sealed|new|async|await|var|dynamic|delegate|event|property|get|set|return|if|else|for|foreach|while|do|switch|case|break|continue|try|catch|finally|throw|yield|from|where|select|join|group|orderby)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"|@\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Types
            ("\\b[A-Z][a-zA-Z0-9]*\\b", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightRuby(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(def|class|module|if|elsif|else|unless|while|until|for|in|do|break|next|return|yield|begin|rescue|ensure|raise|when|case|then|end|and|or|not|true|false|nil|require|include|attr_reader|attr_writer|attr_accessor|private|protected|public|alias|super|self)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"|'[^']*'|:[a-zA-Z_]\\w*", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow (includes symbols)
            // Comments
            ("#.*", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Instance/class variables
            ("@{1,2}\\w+", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightPHP(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(function|class|interface|trait|namespace|use|extends|implements|public|private|protected|static|abstract|final|const|return|if|else|elseif|foreach|while|for|switch|case|break|continue|try|catch|finally|throw|echo|print|isset|empty|die|exit|include|require|include_once|require_once|new|as|instanceof|true|false|null|array)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|#.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Variables
            ("\\$[a-zA-Z_]\\w*", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightShell(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(if|then|else|elif|fi|for|in|do|done|while|case|esac|function|return|export|local|declare|readonly|break|continue)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("#.*", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Variables
            ("\\$[a-zA-Z_]\\w*|\\$\\{[^}]+\\}", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
            // Commands (common ones)
            ("\\b(echo|cd|ls|grep|sed|awk|cut|sort|uniq|head|tail|cat|rm|cp|mv|mkdir|pwd|chmod|chown|find|curl|wget)\\b", NSColor(red: 1.0, green: 0.474, blue: 0.778, alpha: 1.0)), // pink
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightSQL(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(SELECT|FROM|WHERE|JOIN|LEFT|RIGHT|INNER|OUTER|ON|ORDER|BY|GROUP|HAVING|LIMIT|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|TABLE|DROP|ALTER|ADD|COLUMN|PRIMARY|KEY|FOREIGN|CONSTRAINT|INDEX|VIEW|TRIGGER|PROCEDURE|FUNCTION|UNION|ALL|DISTINCT|CASE|WHEN|THEN|ELSE|END|AND|OR|NOT|IN|BETWEEN|LIKE|IS|NULL)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple (case-insensitive)
            // String literals
            ("'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("--.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Functions
            ("\\b(COUNT|SUM|AVG|MIN|MAX|LENGTH|SUBSTR|ROUND|NOW|CURRENT_DATE)\\b", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightYAML(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keys (word followed by colon)
            ("[a-zA-Z_][a-zA-Z0-9_]*(?=:)", NSColor(red: 0.549, green: 0.915, blue: 0.993, alpha: 1.0)), // cyan
            // String literals
            ("'[^']*'|\"[^\"]*\"", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("#.*", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers and booleans
            ("\\b(true|false|yes|no|on|off|null)\\b|\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // List markers
            ("^\\s*[-*]\\s", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightJSON(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keys
            ("\"[^\"]*\"(?=:)", NSColor(red: 0.549, green: 0.915, blue: 0.993, alpha: 1.0)), // cyan
            // String values
            ("\"[^\"]*\"", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Booleans and null
            ("\\b(true|false|null)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // Punctuation (brackets, braces, commas)
            ("[{}\\[\\],:]", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightKotlin(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(fun|class|data|sealed|enum|interface|object|companion|val|var|const|if|else|when|for|while|do|break|continue|return|throw|try|catch|finally|as|is|in|out|where|by|get|set|suspend|inline|infix|operator|tailrec|reified|import|package|typealias|expect|actual)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals
            ("\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(_\\d+)*(\\.\\d+(_\\d+)*)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Type names
            ("\\b[A-Z][a-zA-Z0-9]*\\b", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightGroovy(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Keywords
            ("\\b(def|class|interface|trait|void|boolean|byte|char|short|int|long|float|double|String|boolean|var|if|else|switch|case|for|while|do|break|continue|return|try|catch|finally|throw|new|import|package|assert|as|in|instanceof)\\b", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // String literals (including GString with interpolation)
            ("\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("//.*|/\\*[\\s\\S]*?\\*/", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
            // Numbers
            ("\\b\\d+(\\.\\d+)?\\b", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Closures and GPath
            ("[{}\\[\\]\\->]", NSColor(red: 0.314, green: 0.980, blue: 0.482, alpha: 1.0)), // green
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightXML(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        let patterns: [(pattern: String, color: NSColor)] = [
            // Tags
            ("<[a-zA-Z/][^>]*>", NSColor(red: 0.741, green: 0.576, blue: 0.976, alpha: 1.0)), // purple
            // Attributes
            ("[a-zA-Z_][a-zA-Z0-9_-]*(?==)", NSColor(red: 0.549, green: 0.915, blue: 0.993, alpha: 1.0)), // cyan
            // Attribute values
            ("\"[^\"]*\"|'[^']*'", NSColor(red: 0.945, green: 0.980, blue: 0.549, alpha: 1.0)), // yellow
            // Comments
            ("<!--[\\s\\S]*?-->", NSColor(red: 0.388, green: 0.447, blue: 0.643, alpha: 1.0)), // gray
        ]
        
        applyPatternHighlighting(code, patterns: patterns, to: storage, baseOffset: baseOffset)
    }
    
    private static func highlightAsPlainText(
        _ code: String,
        in storage: NSTextStorage,
        baseOffset: Int
    ) {
        // Just use default foreground color for unknown languages
        let range = NSRange(location: baseOffset, length: code.utf16.count)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(red: 0.973, green: 0.973, blue: 0.949, alpha: 1.0) // #f8f8f2
        ]
        storage.addAttributes(attributes, range: range)
    }
    
    // MARK: - Helper Methods
    
    private static func applyPatternHighlighting(
        _ code: String,
        patterns: [(pattern: String, color: NSColor)],
        to storage: NSTextStorage,
        baseOffset: Int
    ) {
        for (pattern, color) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            
            let nsCode = code as NSString
            let range = NSRange(location: 0, length: nsCode.length)
            let matches = regex.matches(in: code, range: range)
            
            for match in matches {
                let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
                let adjustedRange = NSRange(
                    location: match.range.location + baseOffset,
                    length: match.range.length
                )
                storage.addAttributes(attributes, range: adjustedRange)
            }
        }
    }
    
    // MARK: - Cache Management
    
    /// Clear the cached Splash highlighters
    static func clearCache() {
        splashHighlighters.removeAll()
    }
}
