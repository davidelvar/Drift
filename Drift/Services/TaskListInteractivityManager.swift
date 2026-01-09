
//
//  TaskListInteractivityManager.swift
//  Drift
//
//  Service for handling task list checkbox interactions in the editor
//

import Foundation
import AppKit

// MARK: - Models

struct TaskListItem: Identifiable {
    let id: UUID = UUID()
    let range: NSRange              // Range of entire line (from dash to newline)
    let checkboxRange: NSRange      // Range of [ ] or [x]
    let contentRange: NSRange       // Range of task text
    var isCompleted: Bool
    let indentLevel: Int
    let text: String                // Full task text (e.g., "Task description")
    
    var completionMark: String {
        isCompleted ? "[x]" : "[ ]"
    }
}

struct TaskList: Identifiable {
    let id: UUID = UUID()
    let startLine: Int
    let endLine: Int
    var items: [TaskListItem]
    
    var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        items.count
    }
    
    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount) * 100
    }
}

// MARK: - Main Service

@MainActor
class TaskListInteractivityManager {
    
    /// Regex pattern for task list items: `- [ ] task` or `- [x] task`
    /// Matches: optional whitespace, dash/asterisk/plus, space, bracket with space/x, space, then text
    private let taskListPattern = try! NSRegularExpression(
        pattern: "^(\\s*)[-*+]\\s+\\[([\\s\\xX])\\]\\s+(.*)$",
        options: [.anchorsMatchLines]
    )
    
    /// Find task list item at the given location in text storage
    /// - Parameters:
    ///   - storage: The text storage to search
    ///   - location: Character location in the storage
    /// - Returns: TaskListItem if location is within a task list item, otherwise nil
    func taskListItemAt(in storage: NSTextStorage, location: Int) -> TaskListItem? {
        let text = storage.string
        
        guard location >= 0, location < text.count else { return nil }
        
        // Find the line containing this location
        let substring = text[text.startIndex..<text.index(text.startIndex, offsetBy: location)]
        let linesBeforeLocation = substring.components(separatedBy: .newlines).count - 1
        
        let lines = text.components(separatedBy: .newlines)
        guard linesBeforeLocation < lines.count else { return nil }
        
        let line = lines[linesBeforeLocation]
        
        // Check if this line is a task list item
        guard let match = taskListPattern.firstMatch(
            in: line,
            range: NSRange(line.startIndex..<line.endIndex, in: line)
        ) else { return nil }
        
        // Extract components
        guard match.numberOfRanges >= 4 else { return nil }
        
        let indentRange = match.range(at: 1)
        let checkboxStateRange = match.range(at: 2)
        let contentRange = match.range(at: 3)
        
        let indent = (line as NSString).substring(with: indentRange)
        let checkboxState = (line as NSString).substring(with: checkboxStateRange)
        let content = (line as NSString).substring(with: contentRange)
        
        let isCompleted = checkboxState.lowercased() == "x"
        let indentLevel = indent.count / 2  // Roughly 2 spaces per level
        
        // Calculate absolute ranges in storage
        var lineStartOffset = 0
        for i in 0..<linesBeforeLocation {
            lineStartOffset += lines[i].count + 1  // +1 for newline
        }
        
        let lineEndOffset = lineStartOffset + line.count
        let absoluteCheckboxStart = lineStartOffset + checkboxStateRange.location
        let absoluteCheckboxEnd = absoluteCheckboxStart + checkboxStateRange.length
        let absoluteContentStart = lineStartOffset + contentRange.location
        let absoluteContentEnd = absoluteContentStart + contentRange.length
        
        return TaskListItem(
            range: NSRange(location: lineStartOffset, length: line.count),
            checkboxRange: NSRange(location: absoluteCheckboxStart, length: checkboxStateRange.length),
            contentRange: NSRange(location: absoluteContentStart, length: contentRange.length),
            isCompleted: isCompleted,
            indentLevel: indentLevel,
            text: content
        )
    }
    
    /// Toggle the checkbox state at the given range
    /// - Parameters:
    ///   - storage: The text storage to modify
    ///   - range: Range of the checkbox (typically from taskListItemAt)
    /// - Returns: true if toggle was successful, false otherwise
    func toggleCheckboxAt(in storage: NSTextStorage, range: NSRange) -> Bool {
        guard range.location >= 0, range.location + range.length <= storage.length else {
            return false
        }
        
        let text = storage.string
        let substring = (text as NSString).substring(with: range)
        
        // Determine new state
        let newState: String
        if substring.lowercased() == "x" {
            newState = " "  // Uncheck
        } else {
            newState = "x"  // Check
        }
        
        // Apply change
        let mutableString = storage.mutableString as NSMutableString
        mutableString.replaceCharacters(in: range, with: newState)
        
        return true
    }
    
    /// Get all task lists in the document
    /// - Parameter storage: The text storage to analyze
    /// - Returns: Array of TaskList structures
    func getAllTaskLists(in storage: NSTextStorage) -> [TaskList] {
        let text = storage.string
        let lines = text.components(separatedBy: .newlines)
        
        var taskLists: [TaskList] = []
        var currentTaskList: [TaskListItem] = []
        var currentStartLine = 0
        var lineOffset = 0
        
        for (lineIndex, line) in lines.enumerated() {
            guard let match = taskListPattern.firstMatch(
                in: line,
                range: NSRange(line.startIndex..<line.endIndex, in: line)
            ) else {
                // Not a task list item - save current list if any
                if !currentTaskList.isEmpty {
                    taskLists.append(TaskList(
                        startLine: currentStartLine,
                        endLine: lineIndex - 1,
                        items: currentTaskList
                    ))
                    currentTaskList = []
                }
                lineOffset += line.count + 1
                continue
            }
            
            // Parse this task list item
            guard match.numberOfRanges >= 4 else {
                lineOffset += line.count + 1
                continue
            }
            
            let checkboxStateRange = match.range(at: 2)
            let contentRange = match.range(at: 3)
            let indentRange = match.range(at: 1)
            
            let checkboxState = (line as NSString).substring(with: checkboxStateRange)
            let content = (line as NSString).substring(with: contentRange)
            let indent = (line as NSString).substring(with: indentRange)
            
            let isCompleted = checkboxState.lowercased() == "x"
            let indentLevel = indent.count / 2
            
            let item = TaskListItem(
                range: NSRange(location: lineOffset, length: line.count),
                checkboxRange: NSRange(location: lineOffset + checkboxStateRange.location, length: 1),
                contentRange: NSRange(location: lineOffset + contentRange.location, length: contentRange.length),
                isCompleted: isCompleted,
                indentLevel: indentLevel,
                text: content
            )
            
            if currentTaskList.isEmpty {
                currentStartLine = lineIndex
            }
            
            currentTaskList.append(item)
            lineOffset += line.count + 1
        }
        
        // Don't forget last task list
        if !currentTaskList.isEmpty {
            taskLists.append(TaskList(
                startLine: currentStartLine,
                endLine: lines.count - 1,
                items: currentTaskList
            ))
        }
        
        return taskLists
    }
    
    /// Find the range of a checkbox that was clicked at a visual location
    /// Useful for converting mouse click positions to checkbox ranges
    /// - Parameters:
    ///   - storage: The text storage
    ///   - location: Character location from mouse click
    /// - Returns: Range of the checkbox if at valid location, otherwise nil
    func checkboxRangeAtClickLocation(in storage: NSTextStorage, location: Int) -> NSRange? {
        guard let item = taskListItemAt(in: storage, location: location) else {
            return nil
        }
        
        // Verify click was actually on the checkbox, not just the line
        // Check if location is within the checkbox range (within ~20 pixels)
        if location >= item.checkboxRange.location && location <= item.checkboxRange.location + item.checkboxRange.length {
            return item.checkboxRange
        }
        
        return nil
    }
    
    /// Get task list item containing given location
    /// - Parameters:
    ///   - storage: The text storage
    ///   - location: Character location
    /// - Returns: TaskListItem if found, otherwise nil
    func itemAtLocation(in storage: NSTextStorage, location: Int) -> TaskListItem? {
        return taskListItemAt(in: storage, location: location)
    }
    
    /// Toggle completion state of task at given location
    /// - Parameters:
    ///   - storage: The text storage
    ///   - location: Character location where user clicked
    /// - Returns: true if toggle was successful
    func toggleTaskAtLocation(in storage: NSTextStorage, location: Int) -> Bool {
        guard let item = taskListItemAt(in: storage, location: location) else {
            return false
        }
        
        return toggleCheckboxAt(in: storage, range: item.checkboxRange)
    }
    
    /// Calculate progress for all task lists in document
    /// - Parameter storage: The text storage to analyze
    /// - Returns: Dictionary mapping task list index to completion percentage
    func getAllTaskListProgress(in storage: NSTextStorage) -> [Int: Double] {
        let taskLists = getAllTaskLists(in: storage)
        
        var progress: [Int: Double] = [:]
        for (index, taskList) in taskLists.enumerated() {
            progress[index] = taskList.completionPercentage
        }
        
        return progress
    }
    
    /// Count total tasks and completed tasks in document
    /// - Parameter storage: The text storage
    /// - Returns: Tuple of (total, completed)
    func getTaskStatistics(in storage: NSTextStorage) -> (total: Int, completed: Int) {
        let taskLists = getAllTaskLists(in: storage)
        
        var total = 0
        var completed = 0
        
        for taskList in taskLists {
            total += taskList.totalCount
            completed += taskList.completedCount
        }
        
        return (total, completed)
    }
}
