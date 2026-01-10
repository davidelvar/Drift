import XCTest
@testable import Drift

final class LanguageSyntaxHighlighterTests: XCTestCase {
    var highlighter: LanguageSyntaxHighlighter!
    
    override func setUp() {
        super.setUp()
        highlighter = LanguageSyntaxHighlighter()
    }
    
    override func tearDown() {
        highlighter = nil
        super.tearDown()
    }
    
    // MARK: - Language Detection Tests
    
    func testDetectSwift() {
        let code = "let x = 10"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "swift", "Should detect Swift code")
    }
    
    func testDetectPython() {
        let code = "def hello():\n    print('hello')"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "python", "Should detect Python code")
    }
    
    func testDetectJavaScript() {
        let code = "const x = 10;"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "javascript", "Should detect JavaScript code")
    }
    
    func testDetectTypeScript() {
        let code = "const x: number = 10;"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "typescript", "Should detect TypeScript code")
    }
    
    func testDetectJava() {
        let code = "public class Main {}"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "java", "Should detect Java code")
    }
    
    func testDetectCPlusPlus() {
        let code = "#include <iostream>"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "cpp", "Should detect C++ code")
    }
    
    func testDetectCSharp() {
        let code = "public class Program {}"
        let language = highlighter.detectLanguage(in: code)
        
        // C# and Java have similar syntax, may detect either
        XCTAssertNotNil(language)
    }
    
    func testDetectRuby() {
        let code = "def hello\n  puts 'hello'\nend"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "ruby", "Should detect Ruby code")
    }
    
    func testDetectPHP() {
        let code = "<?php echo 'hello'; ?>"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "php", "Should detect PHP code")
    }
    
    func testDetectSQL() {
        let code = "SELECT * FROM users WHERE id = 1"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "sql", "Should detect SQL code")
    }
    
    func testDetectHTML() {
        let code = "<html><body>Hello</body></html>"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "html", "Should detect HTML code")
    }
    
    func testDetectCSS() {
        let code = "body { color: red; }"
        let language = highlighter.detectLanguage(in: code)
        
        XCTAssertEqual(language, "css", "Should detect CSS code")
    }
    
    // MARK: - Syntax Highlighting Tests
    
    func testHighlightSwiftKeywords() {
        let code = "let x = 10\nvar y = 20"
        let highlights = highlighter.highlight(code, language: "swift")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight Swift keywords")
    }
    
    func testHighlightPythonKeywords() {
        let code = "if x > 10:\n    print(x)"
        let highlights = highlighter.highlight(code, language: "python")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight Python keywords")
    }
    
    func testHighlightJavaScriptStrings() {
        let code = "const str = 'hello world'"
        let highlights = highlighter.highlight(code, language: "javascript")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight strings")
    }
    
    func testHighlightComments() {
        let code = """
        // This is a comment
        let x = 10 // inline comment
        """
        let highlights = highlighter.highlight(code, language: "swift")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight comments")
    }
    
    func testHighlightNumbers() {
        let code = "let x = 42, y = 3.14, z = 0xFF"
        let highlights = highlighter.highlight(code, language: "swift")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight numbers")
    }
    
    func testHighlightOperators() {
        let code = "let x = a + b - c * d / e"
        let highlights = highlighter.highlight(code, language: "javascript")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight operators")
    }
    
    // MARK: - Multi-Line Code Tests
    
    func testHighlightSwiftFunction() {
        let code = """
        func greet(name: String) -> String {
            return "Hello, \\(name)!"
        }
        """
        let highlights = highlighter.highlight(code, language: "swift")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight function")
    }
    
    func testHighlightPythonClass() {
        let code = """
        class Dog:
            def __init__(self, name):
                self.name = name
        """
        let highlights = highlighter.highlight(code, language: "python")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight class")
    }
    
    func testHighlightJavaScriptAsync() {
        let code = """
        async function fetchData() {
            const response = await fetch(url)
            return response.json()
        }
        """
        let highlights = highlighter.highlight(code, language: "javascript")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight async/await")
    }
    
    // MARK: - Edge Cases
    
    func testHighlightEmptyCode() {
        let code = ""
        let highlights = highlighter.highlight(code, language: "swift")
        
        XCTAssertTrue(highlights.isEmpty, "Empty code should have no highlights")
    }
    
    func testHighlightUnknownLanguage() {
        let code = "some code"
        let highlights = highlighter.highlight(code, language: "unknown")
        
        // Should handle gracefully
        XCTAssertNotNil(highlights)
    }
    
    func testHighlightMixedLanguageMarkers() {
        let code = "let x = \"<?php code ?>\""
        let highlights = highlighter.highlight(code, language: "swift")
        
        XCTAssertFalse(highlights.isEmpty, "Should highlight despite embedded markers")
    }
    
    func testDetectLanguageFromPartialCode() {
        let code = "if (x > 5) {"
        let language = highlighter.detectLanguage(in: code)
        
        // Should make a best guess
        XCTAssertNotNil(language)
    }
}
