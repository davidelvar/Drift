# Drift 🌊

**A beautiful, extensible, open-source notes app for macOS.**

Drift is a modern note-taking application built with SwiftUI and SwiftData, designed for writers, developers, and anyone who values a clean, distraction-free writing experience. With full Markdown support, a powerful plugin system, and a focus on privacy, Drift puts you in control of your notes.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

### Writing Experience
- **Beautiful Design** - Native macOS interface that feels right at home
- **Focus Mode** - Full-screen distraction-free writing (⌘⇧F) with a centered, width-constrained editor
- **Markdown Support** - Write in Markdown with live preview, split view, or pure editing modes
- **Rich Formatting Toolbar** - Quick access to bold, italic, strikethrough, code, headings, lists, and quotes
- **Serif Typography in Focus Mode** - Optimized for long-form writing

### Organization
- **Folders** - Organize notes into custom folders with icons
- **Tags** - Add colorful tags to notes for flexible categorization
- **Smart Collections** - Quick access to Favorites, Archive, and Trash
- **Powerful Search** - Full-text search across all your notes instantly
- **Sorting Options** - Sort by date modified, date created, or title

### Technical
- **Fast & Lightweight** - Built with SwiftUI and SwiftData for optimal performance
- **Keyboard First** - Comprehensive keyboard shortcuts for power users
- **Extensible** - Plugin architecture for adding new features
- **Privacy-First** - All data stored locally on your Mac using SwiftData
- **Open Source** - MIT licensed, community-driven development

## 📸 Screenshots

*Coming soon*

## 🚀 Getting Started

### Requirements

- **macOS 14.0** (Sonoma) or later
- **Xcode 15.0** or later (for building from source)

### Building from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/davidelvar/Drift.git
   cd Drift
   ```

2. **Open in Xcode:**
   ```bash
   open Drift.xcodeproj
   ```
   
   Or manually open `Drift.xcodeproj` in Xcode.

3. **Select the target:**
   - In Xcode, ensure "Drift" is selected as the active scheme in the toolbar
   - Select "My Mac" as the run destination

4. **Build and Run:**
   - Press `⌘R` or click the Play button
   - Xcode will compile the project and launch Drift

5. **Troubleshooting:**
   - If you see signing errors, go to the "Drift" target → "Signing & Capabilities" and select your development team
   - Clean build folder (`⌘⇧K`) if you encounter build issues

### Download

Pre-built releases coming soon on the [Releases](https://github.com/davidelvar/Drift/releases) page!

## ⌨️ Keyboard Shortcuts

### General

| Action | Shortcut |
|--------|----------|
| New Note | `⌘N` |
| New Folder | `⌘⇧N` |
| Find in Notes | `⌘F` |
| Focus Mode | `⌘⇧F` |
| Add to Favorites | `⌘D` |
| Archive Note | `⌘E` |
| Move to Trash | `⌘⌫` |
| Toggle Sidebar | `⌃⌘S` |

### Editor Modes

| Action | Shortcut |
|--------|----------|
| Edit Mode | `⌘1` |
| Preview Mode | `⌘2` |
| Split Mode | `⌘3` |

### Text Formatting

| Action | Shortcut |
|--------|----------|
| Bold | `⌘B` |
| Italic | `⌘I` |

*Additional formatting available via the toolbar: strikethrough, code, headings, bullet lists, numbered lists, and block quotes.*

## 🏗️ Architecture

Drift follows a clean MVVM architecture pattern optimized for SwiftUI:

```
Drift/
├── DriftApp.swift        # App entry point and menu commands
├── ContentView.swift     # Main window layout with NavigationSplitView
├── Models/               # SwiftData models
│   ├── Note.swift        # Note model with Markdown content
│   ├── Folder.swift      # Folder organization
│   └── Tag.swift         # Tagging system
├── Views/
│   ├── Sidebar/          # Navigation sidebar with folders and tags
│   ├── NoteList/         # Note list, search, and row views
│   └── Editor/           # Note editor, Markdown renderer, Focus Mode
├── ViewModels/
│   └── AppState.swift    # Central @Observable app state
├── Services/
│   └── NoteService.swift # Data operations and persistence
├── Plugins/              # Plugin system architecture
│   └── Plugin.swift      # Plugin protocols and manager
└── Extensions/           # Swift extensions and utilities
```

### Key Technologies

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Modern persistence framework (replacement for Core Data)
- **@Observable** - New observation macro for reactive state management
- **NavigationSplitView** - Three-column layout for macOS

## 🔌 Plugin System

Drift is designed to be extensible. The plugin architecture allows you to add new features without modifying core code.

### Plugin Types

| Type | Purpose |
|------|---------|
| **EditorPlugin** | Add toolbar items and content transformations |
| **ExportPlugin** | Add new export formats (PDF, HTML, etc.) |
| **ThemePlugin** | Create custom color themes |

### Creating a Plugin

```swift
import SwiftUI

struct MyAwesomePlugin: DriftPlugin {
    typealias ConfigView = EmptyView
    
    let id = "com.yourname.awesomeplugin"
    let name = "Awesome Plugin"
    let description = "Adds awesome features to Drift"
    let version = "1.0.0"
    let author = "Your Name"
    
    var isEnabled: Bool = true
    
    func onLoad() {
        print("🚀 Awesome Plugin loaded!")
    }
    
    func onUnload() {
        print("👋 Awesome Plugin unloaded")
    }
    
    func onAppLaunch() {
        // Initialize your plugin when the app starts
    }
    
    func onNoteCreated(_ note: Note) {
        // React to note creation
    }
    
    func onNoteSaved(_ note: Note) {
        // React to note saves
    }
    
    func configurationView() -> EmptyView {
        EmptyView()
    }
}

// Register in DriftApp.swift
PluginManager.shared.register(MyAwesomePlugin())
```

## 🗺️ Roadmap

### v1.0 ✅ (Current)
- [x] Note creation and editing
- [x] Folder organization
- [x] Tags support with colors
- [x] Search functionality
- [x] Favorites/Archive/Trash
- [x] Plugin architecture
- [x] Markdown preview (Edit/Preview/Split)
- [x] Keyboard shortcuts
- [x] Move notes between folders
- [x] Note count badges
- [x] Focus Mode
- [x] Formatting toolbar
- [x] Note sorting

### v1.1 (Planned)
- [ ] Syntax highlighting in code blocks
- [ ] Custom themes (Light/Dark/Custom)
- [ ] Export to PDF/HTML/Markdown
- [ ] Import from Markdown files
- [ ] Drag and drop support

### v1.2 (Future)
- [ ] iCloud sync
- [ ] Note linking (`[[wiki-style]]`)
- [ ] Templates
- [ ] Quick note (menu bar app)
- [ ] Backlinks panel

### v2.0 (Vision)
- [ ] Real-time collaboration
- [ ] End-to-end encryption
- [ ] iOS/iPadOS companion app
- [ ] AI-powered features (summaries, suggestions)

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

### Ways to Contribute

1. **🐛 Report Bugs** - Found a bug? [Open an issue](https://github.com/davidelvar/Drift/issues/new)
2. **💡 Suggest Features** - Have an idea? Start a [discussion](https://github.com/davidelvar/Drift/discussions)
3. **🔧 Submit PRs** - Code contributions are always welcome
4. **📖 Improve Docs** - Help make our documentation better
5. **🧪 Test** - Help test new features and report issues

### Development Workflow

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Drift.git
   ```
3. **Create** a feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
4. **Make** your changes and commit:
   ```bash
   git commit -m 'Add amazing feature'
   ```
5. **Push** to your branch:
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open** a Pull Request

### Code Guidelines

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful commit messages
- Add comments for complex logic
- Test your changes thoroughly
- Update documentation if needed

## 📄 License

Drift is released under the **MIT License**. See [LICENSE](LICENSE) for details.

```
MIT License

Copyright (c) 2026 David Elvar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/) and [SwiftData](https://developer.apple.com/xcode/swiftdata/)
- Inspired by Bear, iA Writer, Obsidian, and other great note-taking apps
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/davidelvar">David Elvar</a> and the Drift community
</p>

<p align="center">
  <a href="https://github.com/davidelvar/Drift/stargazers">⭐ Star us on GitHub</a>
</p>
