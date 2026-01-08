//
//  NoteEditorView.swift
//  Drift
//
//  Rich text editor with Markdown support
//

import SwiftUI
import SwiftData
import AppKit

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

struct NoteEditorView: View {
    @Bindable var note: Note
    @Bindable var appState: AppState
    
    @AppStorage("editorFont") private var editorFont = "Menlo"
    
    @State private var showingInspector = false
    @State private var selectedRange: NSRange?
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    // Extract title from highest level heading
    private var extractedTitle: String {
        let lines = note.content.split(separator: "\n", omittingEmptySubsequences: false)
        
        // Find highest level heading (lowest # count)
        var highestLevel = 7 // Start higher than h6
        var foundTitle = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check if line starts with # (heading)
            if trimmedLine.hasPrefix("#") {
                let hashCount = trimmedLine.prefix(while: { $0 == "#" }).count
                
                if hashCount < highestLevel {
                    highestLevel = hashCount
                    // Extract text after the # symbols
                    let titleText = trimmedLine
                        .dropFirst(hashCount)
                        .trimmingCharacters(in: .whitespaces)
                    foundTitle = String(titleText)
                }
            }
        }
        
        return foundTitle.isEmpty ? "Untitled" : foundTitle
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Metadata bar with mode picker on left
            HStack(spacing: 16) {
                // Editor mode picker - moved to LEFT
                Picker("Mode", selection: $appState.editorMode) {
                    ForEach(EditorMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 180)
                
                Divider()
                    .frame(height: 16)
                
                // Formatting buttons (only show in Edit or Split mode)
                if appState.editorMode != .Preview {
                    HStack(spacing: 4) {
                        FormatButton(icon: "bold", tooltip: "Bold (⌘B)") {
                            wrapSelection(with: "**")
                        }
                        FormatButton(icon: "italic", tooltip: "Italic (⌘I)") {
                            wrapSelection(with: "_")
                        }
                        FormatButton(icon: "strikethrough", tooltip: "Strikethrough") {
                            wrapSelection(with: "~~")
                        }
                        FormatButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Code") {
                            wrapSelection(with: "`")
                        }
                        
                        Divider()
                            .frame(height: 16)
                        
                        FormatButton(icon: "number", tooltip: "Heading") {
                            insertAtLineStart("# ")
                        }
                        FormatButton(icon: "list.bullet", tooltip: "Bullet List") {
                            insertAtLineStart("- ")
                        }
                        FormatButton(icon: "list.number", tooltip: "Numbered List") {
                            insertAtLineStart("1. ")
                        }
                        FormatButton(icon: "text.quote", tooltip: "Quote") {
                            insertAtLineStart("> ")
                        }
                    }
                }
                
                Spacer()
                
                Label(note.updatedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                
                Label("\(note.wordCount) words", systemImage: "text.word.spacing")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
            Divider()
            
            // Button group above editor (top right)
            HStack(spacing: 12) {
                Spacer()
                
                Button(action: { appState.toggleFocusMode() }) {
                    Image(systemName: "rectangle.dashed")
                }
                .help("Focus Mode (⌘⇧F)")
                
                Button(action: { note.togglePin() }) {
                    Image(systemName: note.isPinned ? "star.fill" : "star")
                        .foregroundStyle(note.isPinned ? .yellow : .secondary)
                }
                .help(note.isPinned ? "Remove from Favorites" : "Add to Favorites")
                
                Button(action: { showingInspector.toggle() }) {
                    Image(systemName: "info.circle")
                }
                .help("Note Info")
                
                ShareLink(item: note.content) {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Share")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .font(.system(size: 14))
            
            // Content area based on mode
            Group {
                switch appState.editorMode {
                case .Edit:
                    editorView
                    
                case .Preview:
                    MarkdownView(content: note.content)
                    
                case .Split:
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            editorView
                                .frame(width: geometry.size.width / 2)
                            
                            Divider()
                            
                            MarkdownView(content: note.content)
                                .frame(width: geometry.size.width / 2)
                        }
                    }
                }
            }
        }
        .background(Color(red: 0.1137, green: 0.1176, blue: 0.1569))
        .frame(minWidth: 500)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Spacer()
                
                Picker("Mode", selection: $appState.editorMode) {
                    ForEach(EditorMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 180)
            }
        }
        .inspector(isPresented: $showingInspector) {
            NoteInspectorView(note: note)
                .inspectorColumnWidth(min: 250, ideal: 300, max: 400)
        }
    }
    
    private var editorView: some View {
        SyntaxHighlightedEditor(text: $note.content, font: editorFont, fontSize: 15)
            .scrollContentBackground(.hidden)
            .focused($isContentFocused)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .onChange(of: note.content) { _, _ in
                note.updatedAt = Date()
            }
    }
    
    // MARK: - Formatting Helpers
    
    private func wrapSelection(with wrapper: String) {
        // Get the current selection from the first responder
        guard let textView = NSApp.keyWindow?.firstResponder as? NSTextView else {
            // If no selection, just insert the wrapper twice
            note.content += "\(wrapper)\(wrapper)"
            return
        }
        
        let selectedRange = textView.selectedRange()
        let text = note.content as NSString
        
        if selectedRange.length > 0 {
            // Wrap selected text
            let selectedText = text.substring(with: selectedRange)
            let wrappedText = "\(wrapper)\(selectedText)\(wrapper)"
            
            let mutableContent = NSMutableString(string: note.content)
            mutableContent.replaceCharacters(in: selectedRange, with: wrappedText)
            note.content = mutableContent as String
            
            // Update selection to be inside the wrapper
            DispatchQueue.main.async {
                textView.setSelectedRange(NSRange(location: selectedRange.location + wrapper.count, length: selectedRange.length))
            }
        } else {
            // Insert wrapper pair and place cursor in middle
            let location = selectedRange.location
            let mutableContent = NSMutableString(string: note.content)
            mutableContent.insert("\(wrapper)\(wrapper)", at: location)
            note.content = mutableContent as String
            
            DispatchQueue.main.async {
                textView.setSelectedRange(NSRange(location: location + wrapper.count, length: 0))
            }
        }
    }
    
    private func insertAtLineStart(_ prefix: String) {
        guard let textView = NSApp.keyWindow?.firstResponder as? NSTextView else {
            note.content = prefix + note.content
            return
        }
        
        let selectedRange = textView.selectedRange()
        let text = note.content as NSString
        
        // Find the start of the current line
        var lineStart = selectedRange.location
        while lineStart > 0 && text.character(at: lineStart - 1) != UInt16(("\n" as Character).asciiValue!) {
            lineStart -= 1
        }
        
        let mutableContent = NSMutableString(string: note.content)
        mutableContent.insert(prefix, at: lineStart)
        note.content = mutableContent as String
        
        DispatchQueue.main.async {
            textView.setSelectedRange(NSRange(location: selectedRange.location + prefix.count, length: 0))
        }
    }
}

// MARK: - Format Button
struct FormatButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovering ? Color.primary.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .help(tooltip)
    }
}

// MARK: - Note Inspector
struct NoteInspectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var note: Note
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var newTagName: String = ""
    @State private var showingAddTag = false
    
    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Created") {
                    Text(note.createdAt.formatted(date: .long, time: .shortened))
                }
                
                LabeledContent("Modified") {
                    Text(note.updatedAt.formatted(date: .long, time: .shortened))
                }
                
                LabeledContent("Words") {
                    Text("\(note.wordCount)")
                }
                
                LabeledContent("Characters") {
                    Text("\(note.characterCount)")
                }
            }
            
            Section("Organization") {
                LabeledContent("Folder") {
                    Text(note.folder?.name ?? "None")
                }
            }
            
            Section("Tags") {
                // Current tags
                if note.tags.isEmpty {
                    Text("No tags")
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(note.tags) { tag in
                            TagBadge(tag: tag) {
                                removeTag(tag)
                            }
                        }
                    }
                }
                
                // Add tag button/field
                if showingAddTag {
                    HStack {
                        TextField("Tag name", text: $newTagName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addTag()
                            }
                        
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTagName.isEmpty)
                        
                        Button("Cancel") {
                            showingAddTag = false
                            newTagName = ""
                        }
                    }
                } else {
                    Button(action: { showingAddTag = true }) {
                        Label("Add Tag", systemImage: "plus")
                    }
                }
                
                // Existing tags to add
                if !availableTags.isEmpty {
                    Divider()
                    Text("Available Tags")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(availableTags) { tag in
                            Button(action: { assignTag(tag) }) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: tag.color))
                                        .frame(width: 8, height: 8)
                                    Text(tag.name)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Section("Status") {
                Toggle("Favorite", isOn: $note.isPinned)
                Toggle("Archived", isOn: $note.isArchived)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Note Info")
    }
    
    private var availableTags: [Tag] {
        allTags.filter { tag in
            !note.tags.contains { $0.id == tag.id }
        }
    }
    
    private func addTag() {
        guard !newTagName.isEmpty else { return }
        
        // Check if tag already exists
        if let existingTag = allTags.first(where: { $0.name.lowercased() == newTagName.lowercased() }) {
            assignTag(existingTag)
        } else {
            // Create new tag with random color
            let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"]
            let newTag = Tag(name: newTagName, color: colors.randomElement()!)
            modelContext.insert(newTag)
            note.tags.append(newTag)
        }
        
        newTagName = ""
        showingAddTag = false
    }
    
    private func assignTag(_ tag: Tag) {
        if !note.tags.contains(where: { $0.id == tag.id }) {
            note.tags.append(tag)
        }
    }
    
    private func removeTag(_ tag: Tag) {
        note.tags.removeAll { $0.id == tag.id }
    }
}

// MARK: - Tag Badge
struct TagBadge: View {
    let tag: Tag
    let onRemove: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: tag.color))
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.caption)
            
            if isHovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: tag.color).opacity(0.2))
        .cornerRadius(6)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Empty State
struct EmptyEditorView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            Text("Select a note")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Choose a note from the list or create a new one")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.1137, green: 0.1176, blue: 0.1569))
    }
}

#Preview {
    let note = Note(title: "Sample Note", content: "This is a sample note with some content to preview.")
    return NoteEditorView(note: note, appState: AppState())
}
