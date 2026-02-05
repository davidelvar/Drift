//
//  SplashCodeBlockView.swift
//  Drift
//
//  Code block view with language badge and improved styling
//  Future: Will integrate Splash for syntax highlighting
//

import SwiftUI

// MARK: - Enhanced Code Block View
struct SplashCodeBlockView: View {
    let code: String
    let language: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Language badge (if specified)
            if !language.isEmpty {
                Text(language.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.576, green: 0.635, blue: 0.792))  // #92a2ca
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.149, green: 0.157, blue: 0.212))  // Secondary
                    .opacity(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Code content
            ScrollView(.horizontal) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .lineSpacing(3.5)
                    .foregroundColor(Color(red: 0.973, green: 0.973, blue: 0.949))  // #f8f8f2
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(red: 0.1137, green: 0.1176, blue: 0.1569))  // Dracula background
        }
        .background(Color(red: 0.149, green: 0.157, blue: 0.212))  // Secondary background
        .cornerRadius(6)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SplashCodeBlockView(
            code: """
            import SwiftUI
            
            struct ContentView: View {
                @State var count = 0
                
                var body: some View {
                    VStack {
                        Text("Count: \\(count)")
                        Button("Increment") {
                            count += 1
                        }
                    }
                }
            }
            """,
            language: "swift"
        )
        
        SplashCodeBlockView(
            code: """
            def fibonacci(n):
                if n <= 1:
                    return n
                return fibonacci(n-1) + fibonacci(n-2)
            """,
            language: "python"
        )
    }
    .padding()
    .background(Color(red: 0.1137, green: 0.1176, blue: 0.1569))
}

