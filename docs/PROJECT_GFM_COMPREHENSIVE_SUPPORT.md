# Project: Comprehensive GitHub Flavored Markdown Support

**Status**: Planning Phase  
**Date**: January 9, 2026  
**Duration**: 4-6 weeks  
**Scope**: Full GFM compliance with extended editor features  
**Owner**: Markdown Architecture Team  
**Version**: 1.0  

---

## Executive Summary

This project elevates Drift's markdown support from functional GFM rendering to comprehensive GFM-first editing. Currently, Drift renders GFM correctly in preview but uses regex-based editor highlighting and lacks interactive editing for tables/task lists. This project delivers:

✅ **Complete GFM Feature Support** — All 14 GFM extensions working in both editor and preview  
✅ **Advanced Syntax Highlighting** — AST-based highlighting for 15+ languages  
✅ **Interactive Editing** — WYSIWYG-style task list and table editing  
✅ **Preview Synchronization** — Live scroll sync between editor and preview  
✅ **Performance Optimized** — Lazy parsing, caching, incremental updates  
✅ **Safety First** — HTML sanitization, link validation, no code injection  

### Key Metrics
- **GFM Spec Compliance**: 100% of spec 0.29
- **Editor Syntax Languages**: 15+ (Swift, Python, JavaScript, Rust, Go, Java, C, C++, C#, Ruby, PHP, Shell, SQL, YAML, JSON)
- **Task List Interactivity**: Click-to-toggle checkboxes
- **Table Editing**: Visual spreadsheet-like UI
- **Performance**: <100ms parse time for 100KB documents
- **Test Coverage**: 90%+ for markdown components

---

## Current State Assessment

### What's Working ✅

| Feature | Status | Quality |
|---------|--------|---------|
| Preview rendering (all GFM) | ✅ | Excellent (swift-markdown-ui v2.4.1) |
| Basic syntax highlighting | ✅ | Good (regex-based) |
| Code block syntax (Swift/Python/JS) | ✅ | Fair (limited) |
| Link and image support | ✅ | Good |
| List rendering | ✅ | Excellent |
| Table rendering | ✅ | Good |
| Task list rendering | ✅ | Good |
| Strikethrough | ✅ | Good |
| Block quotes | ✅ | Good |

### What's Not Working ❌

| Feature | Gap | Impact |
|---------|-----|--------|
| Task list editing | Only checkboxes render; can't click to toggle | Medium |
| Table editing | Read-only; must edit raw markdown | High |
| AST-based highlighting | Uses regex instead | Low-Medium |
| Extended language syntax | Only 3 languages highlighted | Low |
| Scroll sync | Editor/preview misaligned | Medium |
| Autolinks | Not implemented | Low |
| Footnotes | Not supported | Low |
| Callouts/admonitions | Not supported | Low |
| Math expressions | Not supported | Low |

---

## Implementation Phases

### Phase 3A: Foundation (Weeks 1-2)

**Refactor and Unify Highlighting**

#### 3A.1 Merge Highlighting Systems (Days 1-3)
- Consolidate `MarkdownHighlighter` and `SyntaxHighlightedEditor` into single system using AST
- Create new `UnifiedMarkdownHighlighter.swift` using swift-markdown AST
- Remove duplicate code from both current implementations
- Maintain compatibility (same colors, same speed)
- Deliverable: 12 unit tests minimum

#### 3A.2 Integrate Splash More Comprehensively (Days 2-3)
- Expand code block syntax highlighting from 3 languages to 15+
- Add: Rust, Go, Java, C, C++, C#, Ruby, PHP, Shell, SQL, YAML, JSON
- Create language detection from code block fences
- Cache compiled highlighters for performance
- Fallback gracefully for unknown languages

### Phase 3B: Core GFM Features (Weeks 2-3)

#### 3B.1 Task List Interactivity (Days 4-5)
- Make task list checkboxes clickable and editable
- Click checkbox in editor → toggle `[ ]` ↔ `[x]`
- Live preview updates immediately
- Accessible (keyboard navigation)
- Visual feedback (color change, animation)

#### 3B.2 Table Visual Editor (Days 6-8)
- Create spreadsheet-like table editing UI
- Click cell to edit inline
- Arrow keys to navigate
- Right-click for context menu (insert row/column)
- Markdown table syntax updates in background

#### 3B.3 Extended GFM Features (Days 5-6)
- Autolinks — `<https://example.com>` rendered as clickable link
- Footnotes (optional) — `[^1]` with `[^1]: note` at end
- Callouts/Admonitions (optional) — `> **Note:**` styled as callout

### Phase 3C: Advanced Features (Weeks 3-4)

#### 3C.1 Preview Scroll Synchronization (Days 9-11)
- Synchronize editor/preview scroll positions in split mode
- Parse markdown into AST with source positions
- Map line numbers to AST nodes
- Scroll preview to render that node

#### 3C.2 Incremental Parsing & Caching (Days 10-11)
- Optimize parsing for large documents (100KB+)
- Only re-parse changed regions
- Store parsed AST, update on change
- Render only visible preview area
- Wait 500ms after typing before re-parsing

#### 3C.3 Link & URL Validation (Day 12)
- Block dangerous URLs (javascript://, data://, vbscript://)
- Allow safe URLs (https://, http://, mailto://, relative paths)
- Sanitize HTML (no <script>, <iframe>, <embed>)

### Phase 3D: Polish & Testing (Weeks 4-5)

#### 3D.1 Comprehensive Testing (Days 13-17)
- Syntax highlighting tests (24 tests)
- GFM feature tests (32 tests)
- Performance tests (8 tests)
- Safety tests (12 tests)
- Integration tests (16 tests)
- Target: 92 tests minimum, 90%+ coverage

#### 3D.2 Performance Optimization (Days 14-16)
- Background parsing on separate thread
- Highlighting cache (reuse color ranges)
- Lazy preview rendering (render visible area only)
- Debounce frequent operations

#### 3D.3 Documentation & Examples (Days 17-18)
- User guide for GFM features
- Feature parity matrix
- API documentation
- Architecture guide
- Keyboard shortcuts

### Phase 3E: Migration & Launch (Weeks 5-6)

#### 3E.1 Migration to Textual (Days 19-20)
- When Textual (successor to MarkdownUI) is production-ready, plan migration
- Current: swift-markdown-ui in maintenance mode
- Benefits: active maintenance, better performance, more customization

#### 3E.2 Plugin System for Markdown Extensions (Days 21-22)
- Enable third-party markdown extensions via plugins
- Plugin types: language-specific highlighting, custom rendering, AST extensions

---

## Timeline & Milestones

**Total Duration**: 26 days (4-6 weeks with overlapping work)  
**Team Size**: 4-6 people with overlapping responsibilities  
**Start Date**: January 15, 2026 (after Phase 2.1 checkpoint)  
**Target Release**: February 28, 2026  

### Week 1 (Jan 15-19)
- ✅ 3A.1: Merge highlighting systems
- ✅ 3A.2: Add language support (parallel with 3A.1)
- ⏳ Testing & code review

### Week 2 (Jan 22-26)
- ✅ 3B.1: Task list editing
- ✅ 3B.2: Table editor (Days 6-8)
- ⏳ Integration testing

### Week 3 (Jan 29-Feb 2)
- ✅ 3C.1: Scroll sync
- ✅ 3C.2: Incremental parsing
- ✅ 3C.3: URL validation
- ⏳ System testing

### Week 4 (Feb 5-9)
- ✅ 3D.1: Comprehensive testing
- ✅ 3D.2: Performance tuning
- ⏳ Profiling & optimization

### Week 5 (Feb 12-16)
- ✅ 3D.3: Documentation
- ✅ 3E.1: Textual migration planning
- ⏳ Beta testing

### Week 6 (Feb 19-23)
- ✅ 3E.2: Plugin system foundation
- ✅ Release preparation
- ✅ Monitor performance in production

---

## Success Criteria

### Functional ✅
- 100% GFM Spec 0.29 compliance
- Task list checkboxes clickable (< 100ms response)
- Table cells editable with visual UI
- Markdown syntax auto-updates on cell changes
- Undo/redo works with all edits
- 15+ programming languages supported in code blocks
- Accurate highlighting (no false positives)
- Scroll positions sync < 100ms

### Quality ✅
- 90%+ test coverage (92+ tests)
- Parse 100KB document: < 50ms
- Highlight keystroke: < 100ms
- Render preview: < 200ms
- Memory usage: < 100MB for 500KB documents
- Zero crashes or freezes
- Smooth animations (60fps)

### Security ✅
- HTML escaping on all user content
- Dangerous URLs (javascript:, data:) blocked
- No script injection vulnerabilities
- External images require user permission

---

## Architecture Decisions

### Unified Highlighting via AST
**Decision**: Use swift-markdown AST for all highlighting, abandon regex-only approach

**Rationale**:
- More accurate (understands structure, not just patterns)
- Easier to extend with new features
- Better performance (parse once, use for multiple features)
- Enables advanced features (scroll sync, code folding)

### Task List Checkboxes as Inline Editable
**Decision**: Checkboxes are editable in-place, toggle markdown syntax

**Rationale**:
- Matches GitHub behavior
- Fast interactions (no modal dialogs)
- Stores standard markdown (portable)

### Table Editor: Visual UI with Markdown Sync
**Decision**: Show visual table grid, update markdown in background

**Rationale**:
- Familiar spreadsheet UI
- Maintains markdown compatibility
- Works with version control diffs

---

## Dependencies & Libraries

### Required (Already In Use)
- **swift-markdown** (0.7.3) — AST parsing ✅
- **swift-markdown-ui** (2.4.1) — Preview rendering (maintenance mode)
- **STTextView** (2.3.4) — Editor foundation ✅
- **Splash** (0.16.0) — Syntax highlighting ✅

### Optional (For Future Phases)
- **Textual** — Next-gen markdown UI (when released)
- **TreeSitter** — Alternative parsing (if performance needed)

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Table editor complexity | Medium | High | Start with basic table editor, extend later |
| Scroll sync algorithm complexity | Medium | Medium | Prototype with simple line-based sync first |
| Performance degradation with large docs | Low | High | Profile early, use incremental parsing |
| swift-markdown-ui maintenance | Medium | Medium | Monitor Textual release, plan migration |
| Unify highlighting breaks edge cases | Low | Low | Comprehensive testing before shipping |
| Plugin system scope creep | Medium | Low | Define strict plugin API early |

---

## Code Examples

### UnifiedMarkdownHighlighter Template

```swift
import Foundation
import Markdown

@MainActor
final class UnifiedMarkdownHighlighter {
    private let parser = Parser()
    
    struct SyntaxHighlight {
        let range: NSRange
        let attributes: [NSAttributedString.Key: Any]
    }
    
    func highlight(_ text: String) -> [SyntaxHighlight] {
        let document = parser.parse(text)
        var highlights: [SyntaxHighlight] = []
        
        for element in document.children {
            highlights.append(contentsOf: highlightElement(element, in: text))
        }
        
        return highlights
    }
    
    private func highlightElement(_ element: BlockElement, in text: String) -> [SyntaxHighlight] {
        switch element {
        case let heading as Heading:
            return highlightHeading(heading, in: text)
        case let codeBlock as CodeBlock:
            return highlightCodeBlock(codeBlock, in: text)
        default:
            return []
        }
    }
}
```

---

**Status**: ✅ **Ready for Implementation**  
**Next Step**: Execute Phase 3A starting January 15, 2026  
**Reviewers**: 3 (Architecture, Editor Lead, QA)

---

## Quick Links
- GFM Spec: https://github.github.com/gfm/
- swift-markdown: https://github.com/apple/swift-markdown
- Splash: https://github.com/JohnSundell/Splash
- STTextView: https://github.com/paulshen/STTextView
