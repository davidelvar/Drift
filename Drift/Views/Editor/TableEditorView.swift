//
//  TableEditorView.swift
//  Drift
//
//  SwiftUI component for visual GFM table editing
//

import SwiftUI
import AppKit

struct TableEditorView: View {
    @Binding var table: MarkdownTable
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedRow: Int?
    @State private var selectedColumn: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text("Table Editor")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .border(Color.gray.opacity(0.3), width: 1)
            
            // Main editor area
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        ForEach(0..<table.columnCount, id: \.self) { colIdx in
                            TableCellEditView(
                                text: table.headers[colIdx],
                                isHeader: true,
                                isSelected: selectedColumn == colIdx,
                                onSelect: { selectedColumn = colIdx }
                            ) { newValue in
                                table.setHeader(colIdx, to: newValue)
                            }
                            .border(Color.gray.opacity(0.5), width: 1)
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .border(Color.gray, width: 1)
                    
                    // Separator row with alignment indicators
                    HStack(spacing: 0) {
                        ForEach(0..<table.columnCount, id: \.self) { colIdx in
                            VStack(spacing: 4) {
                                Text(table.alignments[colIdx].display)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Divider()
                            }
                            .frame(minWidth: 80)
                            .padding(8)
                            .border(Color.gray.opacity(0.5), width: 1)
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .border(Color.gray, width: 1)
                    
                    // Data rows
                    ForEach(0..<table.rowCount, id: \.self) { rowIdx in
                        HStack(spacing: 0) {
                            ForEach(0..<table.columnCount, id: \.self) { colIdx in
                                TableCellEditView(
                                    text: table.rows[rowIdx][colIdx],
                                    isHeader: false,
                                    isSelected: selectedRow == rowIdx && selectedColumn == colIdx,
                                    onSelect: {
                                        selectedRow = rowIdx
                                        selectedColumn = colIdx
                                    }
                                ) { newValue in
                                    table.setCell(rowIdx, colIdx, to: newValue)
                                }
                                .border(Color.gray.opacity(0.5), width: 1)
                            }
                        }
                        .border(Color.gray, width: 1)
                    }
                }
            }
            
            Divider()
            
            // Toolbar
            HStack(spacing: 12) {
                Button(action: { insertRowAbove() }) {
                    Label("Insert Above", systemImage: "plus.circle")
                        .font(.caption)
                }
                .help("Insert new row above selected")
                
                Button(action: { insertRowBelow() }) {
                    Label("Insert Below", systemImage: "plus.circle")
                        .font(.caption)
                }
                .help("Insert new row below selected")
                
                Divider()
                    .frame(height: 20)
                
                Button(action: { deleteSelectedRow() }) {
                    Label("Delete Row", systemImage: "minus.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .help("Delete selected row")
                .disabled(selectedRow == nil || table.rowCount <= 1)
                
                Spacer()
                
                Button(action: { insertColumnLeft() }) {
                    Label("Insert Left", systemImage: "plus.circle")
                        .font(.caption)
                }
                .help("Insert new column to the left")
                
                Button(action: { insertColumnRight() }) {
                    Label("Insert Right", systemImage: "plus.circle")
                        .font(.caption)
                }
                .help("Insert new column to the right")
                
                Button(action: { deleteSelectedColumn() }) {
                    Label("Delete Col", systemImage: "minus.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .help("Delete selected column")
                .disabled(selectedColumn == nil || table.columnCount <= 1)
                
                Divider()
                    .frame(height: 20)
                
                Menu {
                    Button("Left") {
                        if let col = selectedColumn {
                            table.setAlignment(col, to: .left)
                        }
                    }
                    Button("Center") {
                        if let col = selectedColumn {
                            table.setAlignment(col, to: .center)
                        }
                    }
                    Button("Right") {
                        if let col = selectedColumn {
                            table.setAlignment(col, to: .right)
                        }
                    }
                } label: {
                    Label("Align", systemImage: "line.3.horizontal")
                        .font(.caption)
                }
                .disabled(selectedColumn == nil)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .border(Color.gray.opacity(0.3), width: 1)
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Actions
    
    private func insertRowAbove() {
        guard let row = selectedRow else {
            table.insertRow(at: 0)
            selectedRow = 0
            return
        }
        table.insertRow(at: row)
    }
    
    private func insertRowBelow() {
        guard let row = selectedRow else {
            table.insertRow()
            selectedRow = table.rowCount - 1
            return
        }
        table.insertRow(at: row + 1)
        selectedRow = row + 1
    }
    
    private func deleteSelectedRow() {
        guard let row = selectedRow, table.rowCount > 1 else { return }
        table.deleteRow(at: row)
        selectedRow = min(row, table.rowCount - 1)
    }
    
    private func insertColumnLeft() {
        guard let col = selectedColumn else {
            table.insertColumn(at: 0)
            selectedColumn = 0
            return
        }
        table.insertColumn(at: col)
    }
    
    private func insertColumnRight() {
        guard let col = selectedColumn else {
            table.insertColumn()
            selectedColumn = table.columnCount - 1
            return
        }
        table.insertColumn(at: col + 1)
        selectedColumn = col + 1
    }
    
    private func deleteSelectedColumn() {
        guard let col = selectedColumn, table.columnCount > 1 else { return }
        table.deleteColumn(at: col)
        selectedColumn = min(col, table.columnCount - 1)
    }
}

// MARK: - Table Cell Editor

struct TableCellEditView: View {
    let text: String
    let isHeader: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: (String) -> Void
    
    @State private var editingText: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            Color(isHeader ? NSColor.controlBackgroundColor : NSColor.white)
            
            if isEditing {
                // Editing mode
                TextField("", text: $editingText, onCommit: {
                    onEdit(editingText)
                    isEditing = false
                })
                .textFieldStyle(.roundedBorder)
                .padding(6)
                .onExitCommand {
                    isEditing = false
                    editingText = text
                }
            } else {
                // Display mode
                HStack {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(isHeader ? .primary : .secondary)
                    Spacer()
                }
                .padding(8)
                .onTapGesture(count: 2) {
                    editingText = text
                    isEditing = true
                }
                .onTapGesture {
                    onSelect()
                }
            }
        }
        .frame(minWidth: 80, minHeight: 32)
        .border(
            isSelected ? Color.blue : Color.gray.opacity(0.3),
            width: isSelected ? 2 : 1
        )
        .onAppear {
            editingText = text
        }
    }
}

// MARK: - Preview

#if DEBUG
struct TableEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TableEditorView(
            table: .constant(
                MarkdownTable(
                    headers: ["Name", "Email", "Status"],
                    rows: [
                        ["Alice", "alice@example.com", "Active"],
                        ["Bob", "bob@example.com", "Inactive"],
                        ["Charlie", "charlie@example.com", "Active"]
                    ],
                    alignments: [.left, .center, .right],
                    range: NSRange(location: 0, length: 100)
                )
            )
        )
        .frame(width: 700, height: 500)
    }
}
#endif
