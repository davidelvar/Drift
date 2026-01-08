//
//  SplashHighlightingModifier.swift
//  Drift
//
//  Apply Splash-based markdown highlighting to CodeEditor
//

import SwiftUI
import AppKit

struct SplashHighlightingModifier: ViewModifier {
    let text: String
    let font: NSFont
    
    init(text: String, font: NSFont = NSFont(name: "SFMono-Medium", size: 13) ?? .systemFont(ofSize: 13)) {
        self.text = text
        self.font = font
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                applyHighlighting()
            }
            .onChange(of: text) { _, _ in
                applyHighlighting()
            }
    }
    
    private func applyHighlighting() {
        // Access the CodeEditor's text view through the responder chain
        guard let window = NSApp.keyWindow else { return }
        guard let textView = findTextView(in: window.contentView) else { return }
        
        let highlighted = SplashMarkdownHighlighter.shared.highlight(text)
        textView.textStorage?.setAttributedString(highlighted)
    }
    
    private func findTextView(in view: NSView?) -> NSTextView? {
        guard let view = view else { return nil }
        
        if let textView = view as? NSTextView {
            return textView
        }
        
        for subview in view.subviews {
            if let textView = findTextView(in: subview) {
                return textView
            }
        }
        
        return nil
    }
}

extension View {
    func withSplashHighlighting(text: String, font: NSFont = NSFont(name: "SFMono-Medium", size: 13) ?? .systemFont(ofSize: 13)) -> some View {
        modifier(SplashHighlightingModifier(text: text, font: font))
    }
}
