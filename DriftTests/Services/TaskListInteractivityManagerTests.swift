import XCTest
@testable import Drift

final class TaskListInteractivityManagerTests: XCTestCase {
    var manager: TaskListInteractivityManager!
    
    override func setUp() {
        super.setUp()
        manager = TaskListInteractivityManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    // MARK: - Task Detection Tests
    
    func testDetectSimpleCheckbox() {
        let text = "- [ ] Buy groceries"
        let range = NSRange(location: 0, length: text.utf16.count)
        
        guard let item = manager.taskListItemAt(in: text, location: range.location) else {
            XCTFail("Should detect simple checkbox")
            return
        }
        
        XCTAssertEqual(item.text, "Buy groceries")
        XCTAssertEqual(item.isCompleted, false)
    }
    
    func testDetectCompletedCheckbox() {
        let text = "- [x] Buy groceries"
        let range = NSRange(location: 0, length: text.utf16.count)
        
        guard let item = manager.taskListItemAt(in: text, location: range.location) else {
            XCTFail("Should detect completed checkbox")
            return
        }
        
        XCTAssertEqual(item.text, "Buy groceries")
        XCTAssertEqual(item.isCompleted, true)
    }
    
    func testDetectUppercaseX() {
        let text = "- [X] Buy groceries"
        let range = NSRange(location: 0, length: text.utf16.count)
        
        guard let item = manager.taskListItemAt(in: text, location: range.location) else {
            XCTFail("Should detect uppercase X")
            return
        }
        
        XCTAssertEqual(item.isCompleted, true)
    }
    
    func testDetectNestedCheckbox() {
        let text = "  - [ ] Nested task"
        let range = NSRange(location: 0, length: text.utf16.count)
        
        guard let item = manager.taskListItemAt(in: text, location: range.location) else {
            XCTFail("Should detect nested checkbox")
            return
        }
        
        XCTAssertEqual(item.text, "Nested task")
    }
    
    func testAsteriskBulletCheckbox() {
        let text = "* [ ] Task with asterisk"
        let range = NSRange(location: 0, length: text.utf16.count)
        
        guard let item = manager.taskListItemAt(in: text, location: range.location) else {
            XCTFail("Should detect asterisk bullet")
            return
        }
        
        XCTAssertEqual(item.text, "Task with asterisk")
    }
    
    func testPlusBulletCheckbox() {
        let text = "+ [ ] Task with plus"
        let range = NSRange(location: 0, length: text.utf16.count)
        
        guard let item = manager.taskListItemAt(in: text, location: range.location) else {
            XCTFail("Should detect plus bullet")
            return
        }
        
        XCTAssertEqual(item.text, "Task with plus")
    }
    
    func testNonCheckboxReturnsNil() {
        let text = "- Regular bullet point"
        let range = NSRange(location: 0, length: text.utf16.count)
        
        let item = manager.taskListItemAt(in: text, location: range.location)
        XCTAssertNil(item, "Should not detect non-checkbox items")
    }
    
    // MARK: - Checkbox Toggle Tests
    
    func testToggleCheckboxFromUnchecked() {
        let text = NSMutableAttributedString(string: "- [ ] Buy groceries")
        let range = NSRange(location: 0, length: text.string.utf16.count)
        
        let toggled = manager.toggleCheckboxAt(in: text, range: range)
        XCTAssertTrue(toggled, "Should toggle checkbox")
        XCTAssertTrue(text.string.contains("[x]"), "Should mark as completed")
    }
    
    func testToggleCheckboxFromChecked() {
        let text = NSMutableAttributedString(string: "- [x] Buy groceries")
        let range = NSRange(location: 0, length: text.string.utf16.count)
        
        let toggled = manager.toggleCheckboxAt(in: text, range: range)
        XCTAssertTrue(toggled, "Should toggle checkbox")
        XCTAssertTrue(text.string.contains("[ ]"), "Should mark as uncompleted")
    }
    
    func testToggleNonCheckboxReturnsFalse() {
        let text = NSMutableAttributedString(string: "- Regular item")
        let range = NSRange(location: 0, length: text.string.utf16.count)
        
        let toggled = manager.toggleCheckboxAt(in: text, range: range)
        XCTAssertFalse(toggled, "Should not toggle non-checkbox items")
    }
    
    // MARK: - Task List Collection Tests
    
    func testGetAllTaskLists() {
        let text = """
        - [ ] Task 1
        - [x] Task 2
        * [ ] Task 3
        + [x] Task 4
        """
        
        let taskLists = manager.getAllTaskLists(in: text)
        XCTAssertEqual(taskLists.count, 1, "Should find one task list")
        XCTAssertEqual(taskLists[0].items.count, 4, "Should find all 4 tasks")
    }
    
    func testGetTaskStatistics() {
        let text = """
        - [ ] Task 1
        - [x] Task 2
        - [ ] Task 3
        - [x] Task 4
        - [x] Task 5
        """
        
        let (total, completed) = manager.getTaskStatistics(in: text)
        XCTAssertEqual(total, 5, "Should count total tasks")
        XCTAssertEqual(completed, 3, "Should count completed tasks")
    }
    
    func testTaskStatisticsWithZeroTasks() {
        let text = "No tasks here"
        
        let (total, completed) = manager.getTaskStatistics(in: text)
        XCTAssertEqual(total, 0, "Should return 0 total tasks")
        XCTAssertEqual(completed, 0, "Should return 0 completed tasks")
    }
    
    func testTaskListProgress() {
        let text = """
        - [ ] Task 1
        - [x] Task 2
        - [ ] Task 3
        """
        
        let taskLists = manager.getAllTaskLists(in: text)
        let progress = taskLists[0].progress
        XCTAssertEqual(progress, 1.0 / 3.0, accuracy: 0.01, "Progress should be 33%")
    }
    
    func testEmptyTaskList() {
        let text = ""
        
        let taskLists = manager.getAllTaskLists(in: text)
        XCTAssertEqual(taskLists.count, 0, "Should find no task lists in empty text")
    }
}
