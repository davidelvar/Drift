//
//  MarkdownRenderer.swift
//  Drift
//
//  Markdown preview using swift-markdown-ui with GitHub styling
//

import SwiftUI
import MarkdownUI

// MARK: - Main Markdown View
struct MarkdownView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            Markdown(content)
                .markdownTheme(.gitHub)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(red: 0.0745, green: 0.0784, blue: 0.1098))
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