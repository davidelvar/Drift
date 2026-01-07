//
//  Plugin.swift
//  Drift
//
//  Extensible plugin architecture for Drift
//

import Foundation
import SwiftUI

// MARK: - Plugin Protocol
/// Base protocol for all Drift plugins
protocol DriftPlugin: Identifiable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var version: String { get }
    var author: String { get }
    
    /// Called when the plugin is loaded
    func onLoad()
    
    /// Called when the plugin is unloaded
    func onUnload()
    
    /// Called when the app launches
    func onAppLaunch()
}

// MARK: - Editor Plugin
/// Plugin that can extend the note editor
protocol EditorPlugin: DriftPlugin {
    associatedtype ToolbarContent: View
    
    /// Custom toolbar items to add to the editor
    @ViewBuilder var toolbarItems: ToolbarContent { get }
    
    /// Transform content before saving
    func transformContent(_ content: String) -> String
    
    /// Process content when loading
    func processContent(_ content: String) -> String
}

// MARK: - Export Plugin
/// Plugin that provides export functionality
protocol ExportPlugin: DriftPlugin {
    var exportFormat: String { get }
    var fileExtension: String { get }
    
    func export(note: Note) -> Data?
    func export(notes: [Note]) -> Data?
}

// MARK: - Theme Plugin
/// Plugin that provides custom themes
protocol ThemePlugin: DriftPlugin {
    var themeName: String { get }
    var colorScheme: ColorScheme? { get }
    var accentColor: Color { get }
    var editorFont: Font { get }
}

// MARK: - Plugin Manager
@Observable
final class PluginManager {
    static let shared = PluginManager()
    
    private(set) var loadedPlugins: [any DriftPlugin] = []
    private(set) var editorPlugins: [any EditorPlugin] = []
    private(set) var exportPlugins: [any ExportPlugin] = []
    private(set) var themePlugins: [any ThemePlugin] = []
    
    private init() {}
    
    func register<P: DriftPlugin>(_ plugin: P) {
        loadedPlugins.append(plugin)
        plugin.onLoad()
        
        if let editorPlugin = plugin as? any EditorPlugin {
            editorPlugins.append(editorPlugin)
        }
        if let exportPlugin = plugin as? any ExportPlugin {
            exportPlugins.append(exportPlugin)
        }
        if let themePlugin = plugin as? any ThemePlugin {
            themePlugins.append(themePlugin)
        }
        
        print("📦 Loaded plugin: \(plugin.name) v\(plugin.version)")
    }
    
    func unregister(pluginId: String) {
        if let index = loadedPlugins.firstIndex(where: { $0.id == pluginId }) {
            let plugin = loadedPlugins[index]
            plugin.onUnload()
            loadedPlugins.remove(at: index)
            
            editorPlugins.removeAll { $0.id == pluginId }
            exportPlugins.removeAll { $0.id == pluginId }
            themePlugins.removeAll { $0.id == pluginId }
            
            print("📦 Unloaded plugin: \(plugin.name)")
        }
    }
    
    func notifyAppLaunch() {
        loadedPlugins.forEach { $0.onAppLaunch() }
    }
}

// MARK: - Built-in Export Plugins

/// Markdown export plugin
struct MarkdownExportPlugin: ExportPlugin {
    let id = "com.drift.export.markdown"
    let name = "Markdown Export"
    let description = "Export notes as Markdown files"
    let version = "1.0.0"
    let author = "Drift Team"
    let exportFormat = "Markdown"
    let fileExtension = "md"
    
    func onLoad() {}
    func onUnload() {}
    func onAppLaunch() {}
    
    func export(note: Note) -> Data? {
        let markdown = """
        # \(note.title)
        
        \(note.content)
        
        ---
        *Created: \(note.createdAt.formatted())*
        *Modified: \(note.updatedAt.formatted())*
        """
        return markdown.data(using: .utf8)
    }
    
    func export(notes: [Note]) -> Data? {
        let combined = notes.map { note in
            """
            # \(note.title)
            
            \(note.content)
            
            ---
            """
        }.joined(separator: "\n\n")
        return combined.data(using: .utf8)
    }
}

/// Plain text export plugin
struct PlainTextExportPlugin: ExportPlugin {
    let id = "com.drift.export.plaintext"
    let name = "Plain Text Export"
    let description = "Export notes as plain text files"
    let version = "1.0.0"
    let author = "Drift Team"
    let exportFormat = "Plain Text"
    let fileExtension = "txt"
    
    func onLoad() {}
    func onUnload() {}
    func onAppLaunch() {}
    
    func export(note: Note) -> Data? {
        let text = """
        \(note.title)
        \(String(repeating: "=", count: note.title.count))
        
        \(note.content)
        """
        return text.data(using: .utf8)
    }
    
    func export(notes: [Note]) -> Data? {
        let combined = notes.map { note in
            """
            \(note.title)
            \(String(repeating: "=", count: note.title.count))
            
            \(note.content)
            """
        }.joined(separator: "\n\n---\n\n")
        return combined.data(using: .utf8)
    }
}

/// JSON export plugin
struct JSONExportPlugin: ExportPlugin {
    let id = "com.drift.export.json"
    let name = "JSON Export"
    let description = "Export notes as JSON for backup or migration"
    let version = "1.0.0"
    let author = "Drift Team"
    let exportFormat = "JSON"
    let fileExtension = "json"
    
    func onLoad() {}
    func onUnload() {}
    func onAppLaunch() {}
    
    func export(note: Note) -> Data? {
        let dict: [String: Any] = [
            "id": note.id.uuidString,
            "title": note.title,
            "content": note.content,
            "createdAt": ISO8601DateFormatter().string(from: note.createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: note.updatedAt),
            "isPinned": note.isPinned,
            "isArchived": note.isArchived
        ]
        return try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
    }
    
    func export(notes: [Note]) -> Data? {
        let array = notes.map { note -> [String: Any] in
            [
                "id": note.id.uuidString,
                "title": note.title,
                "content": note.content,
                "createdAt": ISO8601DateFormatter().string(from: note.createdAt),
                "updatedAt": ISO8601DateFormatter().string(from: note.updatedAt),
                "isPinned": note.isPinned,
                "isArchived": note.isArchived
            ]
        }
        return try? JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
    }
}
