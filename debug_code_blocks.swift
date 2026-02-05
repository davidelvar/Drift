#!/usr/bin/env swift

import Foundation

// Simple test harness for code block detection logic

func getCodeBlockRanges(_ string: String) -> [(start: Int, length: Int)] {
    let lines = string.components(separatedBy: .newlines)
    var codeBlockRanges: [(start: Int, length: Int)] = []
    var inCodeBlock = false
    var blockStartPosition = 0
    var currentPosition = 0
    
    for line in lines {
        if line.starts(with: "```") {
            if inCodeBlock {
                // Closing fence
                let blockEnd = currentPosition + line.count
                codeBlockRanges.append((start: blockStartPosition, length: blockEnd - blockStartPosition))
                inCodeBlock = false
            } else {
                // Opening fence
                blockStartPosition = currentPosition
                inCodeBlock = true
            }
        }
        
        currentPosition += line.count + 1
    }
    
    return codeBlockRanges
}

// Test 1: Simple code block
print("Test 1: Simple code block")
let test1 = """
Some text
```
let x = 42
```
More text
"""

let ranges1 = getCodeBlockRanges(test1)
print("Found \(ranges1.count) code block(s)")
if ranges1.count > 0 {
    let range = ranges1[0]
    let startIndex = test1.index(test1.startIndex, offsetBy: range.start)
    let endIndex = test1.index(startIndex, offsetBy: range.length)
    let content = String(test1[startIndex..<endIndex])
    print("Range: location=\(range.start), length=\(range.length)")
    print("Content:\n\(content)")
    print("---")
}

// Test 2: Your problematic Python code
print("\nTest 2: Python code with underscores")
let test2 = """
```python
while game_is_running:
    process_input()
    update_state(delta_time)
    render()
    wait_for_next_frame()
```
"""

let ranges2 = getCodeBlockRanges(test2)
print("Found \(ranges2.count) code block(s)")
if ranges2.count > 0 {
    let range = ranges2[0]
    let startIndex = test2.index(test2.startIndex, offsetBy: range.start)
    let endIndex = test2.index(startIndex, offsetBy: range.length)
    let content = String(test2[startIndex..<endIndex])
    print("Range: location=\(range.start), length=\(range.length)")
    print("Content:\n\(content)")
    
    // Check if underscores are included
    if content.contains("game_is_running") {
        print("✓ Contains game_is_running with underscores")
    } else {
        print("✗ Missing game_is_running with underscores")
    }
}

// Test 3: Multiple code blocks
print("\nTest 3: Multiple code blocks")
let test3 = """
```swift
let x = 42
```

Some text

```python
x = 42
```
"""

let ranges3 = getCodeBlockRanges(test3)
print("Found \(ranges3.count) code block(s)")
for (i, range) in ranges3.enumerated() {
    let startIndex = test3.index(test3.startIndex, offsetBy: range.start)
    let endIndex = test3.index(startIndex, offsetBy: range.length)
    let content = String(test3[startIndex..<endIndex])
    print("Block \(i+1): location=\(range.start), length=\(range.length)")
    print("Content:\n\(content)")
    print("---")
}

// Test 4: No code blocks
print("\nTest 4: Text with no code blocks")
let test4 = "Just some regular text without any code blocks"
let ranges4 = getCodeBlockRanges(test4)
print("Found \(ranges4.count) code block(s)")
if ranges4.count == 0 {
    print("✓ Correctly identified no code blocks")
}

// Test 5: Unclosed code block
print("\nTest 5: Unclosed code block")
let test5 = """
```python
def hello():
    print("world")

(no closing backticks)
"""

let ranges5 = getCodeBlockRanges(test5)
print("Found \(ranges5.count) code block(s)")
if ranges5.count == 0 {
    print("✓ Correctly identified incomplete code block")
}
