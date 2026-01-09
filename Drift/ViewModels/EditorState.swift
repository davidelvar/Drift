//
//  EditorState.swift
//  Drift
//
//  Editor-specific state management
//

import Foundation
import SwiftUI

enum EditorMode: String, CaseIterable {
    case Edit
    case Preview
    case Split
    
    var icon: String {
        switch self {
        case .Edit: return "pencil"
        case .Preview: return "eye"
        case .Split: return "rectangle.split.2x1"
        }
    }
}

@Observable
final class EditorState {
    var editorMode: EditorMode = .Edit
    var isFocusMode: Bool = false
    var isEditing: Bool = false
    
    init() {}
    
    func toggleFocusMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFocusMode.toggle()
        }
    }
    
    func setEditorMode(_ mode: EditorMode) {
        editorMode = mode
    }
}
