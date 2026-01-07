//
//  EditorSettingsView.swift
//  Drift
//
//  Editor settings and preferences
//

import SwiftUI

struct EditorSettingsView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let editorFonts = ["Menlo", "Monaco", "Courier New"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Editor Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
            
            Form {
                Section("Font") {
                    Picker("Font", selection: $appState.editorFont) {
                        ForEach(editorFonts, id: \.self) { font in
                            Text(font)
                                .tag(font)
                        }
                    }
                }
            }
            .padding(20)
            
            Spacer()
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    EditorSettingsView(appState: AppState())
}
