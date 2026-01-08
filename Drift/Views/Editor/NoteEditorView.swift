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
    
    @AppStorage("editorFont") private var editorFont = "Monaco"
    @AppStorage("editorFontSize") private var editorFontSize = 15.0
    @AppStorage("editorShowLineNumbers") private var showLineNumbers = true
    @AppStorage("editorHighlightSelectedLine") private var highlightSelectedLine = true
    @AppStorage("editorWrapLines") private var wrapLines = true
    @AppStorage("editorLineHeightMultiple") private var lineHeightMultiple = 1.5
    @AppStorage("editorTabWidth") private var tabWidth = 4
    @AppStorage("editorSpellCheck") private var spellCheck = true
    @AppStorage("editorSmartQuotes") private var smartQuotes = false
    @AppStorage("editorSmartDashes") private var smartDashes = false
    
    // Helper to get font with fallback
    private func getFont(name: String, size: Double) -> NSFont {
        let fontFallbacks = [name, "Monaco", "Menlo", "SF Mono", "Courier New", "Andale Mono"]
        
        for fontName in fontFallbacks {
            if let font = NSFont(name: fontName, size: size) {
                return font
            }
        }
        
        // Final fallback to system monospace
        return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
    
    @State private var showingInspector = false
    @State private var selectedRange: NSRange?
    @State private var previousContent: String = ""
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Metadata bar with mode picker on left
            HStack(spacing: 16) {
                // Editor mode picker - moved to LEFT
                // Picker("Mode", selection: $appState.editorMode) {
                //     ForEach(EditorMode.allCases, id: \.self) { mode in
                //         Label(mode.rawValue, systemImage: mode.icon)
                //             .tag(mode)
                //     }
                // }
                // .pickerStyle(.segmented)
                // .labelsHidden()
                // .frame(width: 180)
                
                // Divider()
                //     .frame(height: 16)
                
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
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            
            Divider()
            
            // Button group above editor (top right)
            
            .padding(.horizontal, 0)
            .padding(.vertical, 0)
            .font(.system(size: 14))
            
            // Content area based on mode
            ZStack(alignment: .bottomTrailing) {
                Group {
                    switch appState.editorMode {
                    case .Edit:
                        editorView
                        
                    case .Preview:
                        MarkdownView(content: note.content)
                            .padding(.leading, 16)
                        
                    case .Split:
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                editorView
                                    .frame(width: geometry.size.width / 2)
                                
                                Divider()
                                
                                MarkdownView(content: note.content)
                                    .frame(width: geometry.size.width / 2)
                                    .padding(.leading, 16)
                            }
                        }	
                    }
                }
                
                // Mode picker - bottom right with glass effect
                Picker("Mode", selection: $appState.editorMode) {
                    ForEach(EditorMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 180)
                .padding(16)
                .background(Color.black.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .background(Color(red: 0.0745, green: 0.0784, blue: 0.1098))
        .tint(Color(red: 0.114, green: 0.118, blue: 0.157))
        .frame(minWidth: 500)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Spacer()
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { appState.toggleFocusMode() }) {
                    Image("focus")
                }
                .help("Focus Mode (⌘⇧F)")
                
                Button(action: { note.togglePin() }) {
                    Image(note.isPinned ? "star-full" : "star-empty")
                }
                .help(note.isPinned ? "Remove from Favorites" : "Add to Favorites")
                
                Button(action: { showingInspector.toggle() }) {
                    Image("circle-info")
                }
                .help("Note Info")
                
                ShareLink(item: note.content) {
                    Image("export")
                }
                .help("Share")
            }
        }
        .inspector(isPresented: $showingInspector) {
            NoteInspectorView(note: note)
                .inspectorColumnWidth(min: 250, ideal: 300, max: 400)
        }
    }
    
    private var editorView: some View {
        STTextViewRepresentable(
            text: $note.content,
            font: getFont(name: editorFont, size: editorFontSize),
            textColor: NSColor(red: 0.973, green: 0.973, blue: 0.949, alpha: 1.0),
            backgroundColor: NSColor(red: 0.0745, green: 0.0784, blue: 0.1098, alpha: 1.0),
            showLineNumbers: showLineNumbers,
            highlightSelectedLine: highlightSelectedLine,
            wrapLines: wrapLines,
            lineHeightMultiple: lineHeightMultiple,
            tabWidth: tabWidth,
            spellCheck: spellCheck,
            smartQuotes: smartQuotes,
            smartDashes: smartDashes
        )
        .frame(minWidth: 200, minHeight: 200)
        .padding(.leading, 24)
        .padding(.vertical, 12)
        .focused($isContentFocused)
        .onChange(of: note.id) { _, _ in
            // When note changes, update previousContent to current content
            previousContent = note.content
        }
        .onChange(of: note.content) { oldValue, newValue in
            // Only update timestamp if content actually changed from what we remember
            // This prevents updates when just switching to a note
            if newValue != previousContent && newValue != oldValue {
                note.updatedAt = Date()
                note.title = note.extractedTitle
            }
            previousContent = newValue
        }
    }
    
    // Dracula dark theme colors
    
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
                .foregroundStyle(Color(red: 0.384, green: 0.447, blue: 0.643))
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
//        .navigationTitle("Note Info")
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
            Image("select-note")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
            
            Text("Select a note")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Choose a note from the list or create a new one")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.0745, green: 0.0784, blue: 0.1098))
    }
}

// MARK: - STTextView Wrapper
struct STTextViewRepresentable: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool = true
    var font: NSFont?
    var textColor: NSColor = .white
    var backgroundColor: NSColor = NSColor(red: 0.0745, green: 0.0784, blue: 0.1098, alpha: 1.0)
    var showLineNumbers: Bool = true
    var highlightSelectedLine: Bool = true
    var wrapLines: Bool = true
    var lineHeightMultiple: Double = 1.5
    var tabWidth: Int = 4
    var spellCheck: Bool = true
    var smartQuotes: Bool = false
    var smartDashes: Bool = false
    
    func makeNSView(context: Context) -> NSView {
        let textView = NSTextView()
        
        textView.string = text
        textView.font = font ?? NSFont(name: "Monaco", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = textColor
        textView.backgroundColor = backgroundColor
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isSelectable = true
        
        // Configure text container for proper line selection
        textView.textContainer?.widthTracksTextView = wrapLines
        if !wrapLines {
            textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        
        // Apply markdown highlighting
        if let storage = textView.textStorage {
            MarkdownHighlighter.highlight(text, in: storage)
        }
        
        // Create scroll view
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.rulersVisible = false
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let scrollView = nsView as? NSScrollView,
              let textView = scrollView.documentView as? NSTextView else { return }
        
        // Always sync the coordinator binding to ensure it's current
        context.coordinator.textBinding = $text
        
        // Update text if changed
        if textView.string != text {
            let cursorPosition = textView.selectedRange().location
            textView.string = text
            
            // Re-apply highlighting
            if let storage = textView.textStorage {
                MarkdownHighlighter.highlight(text, in: storage)
            }
            
            // Restore cursor position if valid
            if cursorPosition <= text.count {
                textView.setSelectedRange(NSRange(location: cursorPosition, length: 0))
            } else {
                // Move cursor to end if text is shorter than before
                textView.setSelectedRange(NSRange(location: text.count, length: 0))
            }
        }
        
        // Update font
        if let font = font {
            textView.font = font
        }
        
        // Update text container wrapping
        textView.textContainer?.widthTracksTextView = wrapLines
        if !wrapLines {
            textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var textBinding: Binding<String>
        
        init(text: Binding<String>) {
            self.textBinding = text
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Only update if text actually changed to avoid feedback loops
            if textView.string != textBinding.wrappedValue {
                textBinding.wrappedValue = textView.string
            }
            
            // Highlight markdown on change
            if let storage = textView.textStorage {
                MarkdownHighlighter.highlight(textView.string, in: storage)
            }
        }
    }
}


#Preview {
    let note = Note(title: "Sample Note", content: "This is a sample note with some content to preview.")
    return NoteEditorView(note: note, appState: AppState())
}
