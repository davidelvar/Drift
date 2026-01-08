//
//  View+DoubleClick.swift
//  Drift
//
//  Extension to detect double-click on views
//

import SwiftUI

extension View {
    func onDoubleClick(perform action: @escaping () -> Void) -> some View {
        modifier(DoubleClickModifier(action: action))
    }
}

struct DoubleClickModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture(count: 2) {
                action()
            }
    }
}
