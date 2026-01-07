//
//  SettingsView.swift
//  Drift
//
//  Settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let editorFonts = ["Menlo", "Monaco", "Courier New"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
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
                Section("Editor") {
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
    SettingsView(appState: AppState())
}
