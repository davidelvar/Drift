//
//  SidebarState.swift
//  Drift
//
//  Sidebar navigation state management
//

import Foundation
import SwiftUI

@Observable
final class SidebarState {
    var selectedSidebarItem: SidebarItem = .allNotes
    var isSidebarVisible: Bool = true
    var isInspectorVisible: Bool = false
    
    init() {}
    
    func selectItem(_ item: SidebarItem) {
        selectedSidebarItem = item
    }
    
    func toggleSidebar() {
        withAnimation {
            isSidebarVisible.toggle()
        }
    }
    
    func toggleInspector() {
        withAnimation {
            isInspectorVisible.toggle()
        }
    }
}
