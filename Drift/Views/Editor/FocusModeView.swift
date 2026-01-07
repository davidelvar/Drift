//
//  FocusModeView.swift
//  Drift
//
//  Distraction-free writing mode
//

import SwiftUI

struct FocusModeView: View {
    @Bindable var note: Note
    @Bindable var appState: AppState
    
    @State private var showControls = false
    @State private var hideControlsTask: Task<Void, Never>?
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        ZStack {
            // Dark background
            Color(nsColor: .windowBackgroundColor)
            
            // Main content
            VStack(spacing: 0) {
                // Top bar (appears on hover)
                if showControls {
                    HStack {
                        Button(action: { appState.toggleFocusMode() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left")
                                Text("Exit Focus Mode")
                            }
                            .font(.system(size: 13, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.05))
                        )
                        
                        Spacer()
                        
                        // Word count
                        Text("\(note.wordCount) words")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 48)  // Extra padding for title bar area
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Writing area - full width ScrollView with centered content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title
                        TextField("Title", text: $note.title)
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .textFieldStyle(.plain)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        // Content editor
                        TextEditor(text: $note.content)
                            .font(.system(size: 18, design: .serif))
                            .scrollContentBackground(.hidden)
                            .scrollDisabled(true)
                            .focused($isEditorFocused)
                            .lineSpacing(8)
                            .frame(minHeight: 500)
                            .onChange(of: note.content) { _, _ in
                                note.updatedAt = Date()
                            }
                    }
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)  // Center the constrained content
                    .padding(.horizontal, 48)
                    .padding(.top, showControls ? 16 : 60)
                    .padding(.bottom, 60)
                }
                
                // Bottom hint (appears on hover)
                if showControls {
                    Text("Press ⌘⇧F or Escape to exit")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            isEditorFocused = true
            showControlsBriefly()
        }
        .onHover { hovering in
            if hovering {
                withAnimation(.easeOut(duration: 0.2)) {
                    showControls = true
                }
                scheduleHideControls()
            }
        }
        .onTapGesture {
            // Hide controls when tapping the writing area
            withAnimation(.easeOut(duration: 0.3)) {
                showControls = false
            }
        }
        .onExitCommand {
            // Escape key exits focus mode
            appState.toggleFocusMode()
        }
    }
    
    private func showControlsBriefly() {
        withAnimation(.easeOut(duration: 0.2)) {
            showControls = true
        }
        scheduleHideControls()
    }
    
    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showControls = false
                    }
                }
            }
        }
    }
}

#Preview {
    FocusModeView(
        note: Note(title: "My Note", content: "Some content here..."),
        appState: AppState()
    )
    .frame(width: 1000, height: 700)
}
