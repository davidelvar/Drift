//
//  DriftApp.swift
//  Drift
//
//  A beautiful, extensible notes app for macOS
//

import SwiftUI
import SwiftData

@main
struct DriftApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Note.self,
            Folder.self,
            Tag.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    NotificationCenter.default.post(name: .createNewNote, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Folder") {
                    NotificationCenter.default.post(name: .createNewFolder, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            // Edit menu additions
            CommandGroup(after: .pasteboard) {
                Divider()
                
                Button("Find in Notes") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            
            // Notes menu
            CommandMenu("Notes") {
                Button("Add to Favorites") {
                    NotificationCenter.default.post(name: .togglePin, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Divider()
                
                Button("Archive Note") {
                    NotificationCenter.default.post(name: .archiveNote, object: nil)
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Button("Move to Trash") {
                    NotificationCenter.default.post(name: .moveToTrash, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
            
            // View menu
            CommandMenu("View") {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
                
                Button("Focus Mode") {
                    NotificationCenter.default.post(name: .toggleFocusMode, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Edit Mode") {
                    NotificationCenter.default.post(name: .setEditorMode, object: "edit")
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Preview Mode") {
                    NotificationCenter.default.post(name: .setEditorMode, object: "preview")
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Split Mode") {
                    NotificationCenter.default.post(name: .setEditorMode, object: "split")
                }
                .keyboardShortcut("3", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let createNewNote = Notification.Name("createNewNote")
    static let createNewFolder = Notification.Name("createNewFolder")
    static let togglePin = Notification.Name("togglePin")
    static let moveToTrash = Notification.Name("moveToTrash")
    static let archiveNote = Notification.Name("archiveNote")
    static let focusSearch = Notification.Name("focusSearch")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let setEditorMode = Notification.Name("setEditorMode")
    static let toggleFocusMode = Notification.Name("toggleFocusMode")
}

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("editorFontSize") private var editorFontSize = 15.0
    @AppStorage("showWordCount") private var showWordCount = true
    @AppStorage("autoSave") private var autoSave = true
    
    var body: some View {
        TabView {
            Form {
                Section("Editor") {
                    Slider(value: $editorFontSize, in: 12...24, step: 1) {
                        Text("Font Size: \(Int(editorFontSize))")
                    }
                    
                    Toggle("Show Word Count", isOn: $showWordCount)
                    Toggle("Auto-save", isOn: $autoSave)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            Form {
                Section("Keyboard Shortcuts") {
                    shortcutRow("New Note", shortcut: "⌘N")
                    shortcutRow("New Folder", shortcut: "⌘⇧N")
                    shortcutRow("Find in Notes", shortcut: "⌘F")
                    shortcutRow("Add to Favorites", shortcut: "⌘D")
                    shortcutRow("Archive Note", shortcut: "⌘E")
                    shortcutRow("Move to Trash", shortcut: "⌘⌫")
                    Divider()
                    shortcutRow("Edit Mode", shortcut: "⌘1")
                    shortcutRow("Preview Mode", shortcut: "⌘2")
                    shortcutRow("Split Mode", shortcut: "⌘3")
                    shortcutRow("Focus Mode", shortcut: "⌘⇧F")
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Shortcuts", systemImage: "keyboard")
            }
            
            Form {
                Section("About Drift") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                    
                    Link("GitHub Repository", destination: URL(string: "https://github.com")!)
                    Link("Report an Issue", destination: URL(string: "https://github.com")!)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 300)
    }
    
    private func shortcutRow(_ action: String, shortcut: String) -> some View {
        HStack {
            Text(action)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
