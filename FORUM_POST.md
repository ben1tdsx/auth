# Per-Window Edit Ownership with Dependency-Based Read Access

## TL;DR (Summary)

Allow each Cursor window to "own" one project for editing, while still being able to read related projects for context. This prevents file conflicts when working on multiple related projects simultaneously.

**In simple terms:** Each window can edit one project, read others, and never conflict.

---

## Why This Matters

Working with monorepos or related projects is common, but current Cursor behavior can cause:

- **Lost work** when multiple windows edit the same file
- **Confusion** about which window can edit what
- **Inability** to use separate windows for clean edit/build/run cycles

This feature solves all of these problems while maintaining full AI context across all projects.

---

## Problem Statement

When working with monorepos or related projects, developers need:

1. **Separate windows for edit/build/run cycles** - Each project needs its own terminal and focus
2. **Full context across related projects** - AI needs to understand relationships between projects
3. **No file conflicts** - Multiple windows editing the same files causes conflicts and lost work
4. **Clear ownership boundaries** - Know which window can edit which files

### Current Limitations

- Multiple Cursor windows can edit the same files, causing conflicts
- No way to restrict edits per window while maintaining read access
- No automatic resolution of parent-child directory relationships
- No dependency system for related projects

### Simple Example

You have a backend project and a frontend project that depend on each other:

- **Window 1**: Edit backend code
- **Window 2**: Edit frontend code
- **Both windows**: Can read each other's code for context
- **No conflicts**: Each window can only edit its own project

### Detailed Example Scenario

```
Project Structure:
my-project/
├── index.js (main API service)
├── package.json
├── subprojects/
│   └── web-client/ (depends on main project)
│       ├── app.js
│       └── package.json
└── shared-resources/ (shared resource)

Developer wants:
- Window 1: Edit main project (index.js, package.json)
- Window 2: Edit web-client subproject (app.js)
- Both windows: Read access to each other's code for context
- No conflicts: Each window can only edit its own files
```

---

## Proposed Solution

### Core Concept

1. **Root Directory Ownership**: Each Cursor window owns one root directory (the folder you open in a window) for editing
2. **Exclusive Ownership**: Cursor enforces that only one window can own a root directory for editing at any time
3. **Dependency-Based Read Access**: Projects declare dependencies (other projects) for read-only access
4. **Parent-Child Hierarchy**: Automatic resolution of nested directory ownership (when one project is inside another)

### Key Rules

#### 1. Root Directory Ownership
- Each Cursor window has a root directory (the folder opened in that window)
- Only one window can own a root directory for editing at any time
- Cursor enforces this globally across all windows
- Attempting to open the same root in another window shows a warning and offers read-only mode

#### 2. Edit Permissions
- A window can edit files within its root directory
- A window cannot edit files outside its root directory
- Multiple windows cannot set the same root directory for editing

#### 3. Dependency-Based Read Access
- Each project can declare dependencies (other projects) via `.cursorproject` file
- Windows can read/index dependent projects for AI context
- Dependencies are read-only in the dependent window
- Supports relative and absolute paths

#### 4. Parent-Child Hierarchy
- If Window A owns `/parent` and Window B owns `/parent/child`:
  - Window B can edit `/parent/child` (child owns its directory)
  - Window A can read `/parent/child` (read-only access)
  - Window A can edit `/parent` (except `/parent/child`)
- Prevents conflicts while maintaining context

---

## Implementation Details

### Configuration File: `.cursorproject`

Each project can define its ownership and dependencies using a simple JSON file:

```json
{
  "name": "main-api",
  "root": ".",
  "dependencies": [
    "../shared-utils",
    "../common-config"
  ],
  "editBoundary": {
    "include": ["**/*"],
    "exclude": ["subprojects/**"]
  }
}
```

**Example for subproject:**
```json
{
  "name": "web-client",
  "root": ".",
  "dependencies": [
    "../../",
    "../../shared-resources"
  ],
  "editBoundary": {
    "include": ["**/*"],
    "exclude": ["../../index.js", "../../package.json"]
  }
}
```

### Cursor Application Behavior

#### 1. Window Opens with Root Directory
- Check if another window owns this root
- If yes: Show warning dialog with options:
  - Open in read-only mode (can read, cannot edit)
  - Close other window and take ownership
  - Cancel
- If no: Grant edit ownership

#### 2. Dependency Resolution
- Read `.cursorproject` files in root and dependencies
- Resolve dependency paths (relative/absolute)
- Grant read access to dependencies
- Deny edit access to dependencies
- Cache dependency graph for performance

#### 3. Parent-Child Detection
- Detect if window root is a subdirectory of another window's root
- Child window: Full edit access to its root
- Parent window: Read-only access to child's root
- Automatic conflict prevention

#### 4. Visual Indicators
- Status bar shows ownership status: "Editing: main-api" or "Read-only: web-client"
- File explorer shows icons:
  - 🔓 Editable files (within root)
  - 🔒 Read-only files (dependencies or child directories)
- Dependency relationships visible in project view
- Warning when attempting to edit read-only file

### File System Behavior

#### Edit Attempts on Read-Only Files
- Show warning dialog: "This file is read-only. It belongs to [project-name]."
- Options:
  - Open in read-only mode (view only)
  - Request ownership transfer (if other window is open)
  - Cancel

#### Ownership Transfer
- Allow transferring ownership between windows
- Warn about unsaved changes
- Handle file locks gracefully
- Update ownership state globally

---

## Benefits

1. **No File Conflicts**: Enforced ownership prevents multiple windows from editing the same files
2. **Full Context**: Read access to dependencies allows AI to understand relationships
3. **Clean Workflow**: Dedicated windows for edit/build/run cycles per project
4. **Automatic Resolution**: Parent-child relationships handled automatically
5. **Explicit Dependencies**: Clear declaration of project relationships
6. **Safe Development**: Prevents accidental edits to wrong project
7. **Better AI Assistance**: AI has full context while respecting edit boundaries

---

## Use Cases

### Use Case 1: Monorepo Development
```
monorepo/
├── packages/
│   ├── auth/ (Window 1)
│   ├── api/ (Window 2, depends on auth)
│   └── ui/ (Window 3, depends on auth and api)
└── shared/ (read by all)
```

### Use Case 2: Related Projects
```
projects/
├── backend/ (Window 1)
├── frontend/ (Window 2, depends on backend)
└── shared/ (read by both)
```

### Use Case 3: Parent-Child Projects
```
main-project/ (Window 1)
└── subprojects/
    └── microservice/ (Window 2, child of main-project)
```

---

## Implementation Phases

### Phase 1: Basic Ownership (MVP)
- Root directory ownership tracking
- Prevent duplicate ownership
- Basic read-only enforcement
- Visual indicators in status bar

### Phase 2: Dependencies
- `.cursorproject` file support
- Dependency resolution (finding and loading related projects)
- Read access to dependencies
- Dependency graph visualization

### Phase 3: Parent-Child Hierarchy
- Automatic parent-child detection
- Hierarchy resolution
- Conflict prevention
- Nested ownership handling

### Phase 4: Advanced Features
- Ownership transfer UI
- Workspace file integration
- Git integration (ownership in git status)
- Performance optimizations (caching, lazy loading)

---

## Example User Flow

1. Developer opens `my-project/` in Window 1
   - Cursor grants edit ownership
   - Status bar: "Editing: main-api"

2. Developer opens `my-project/subprojects/web-client/` in Window 2
   - Cursor detects parent-child relationship
   - Window 2 gets edit ownership of subproject
   - Window 1 gets read-only access to subproject
   - Status bar: "Editing: web-client"

3. Developer tries to edit `../../index.js` in Window 2
   - Cursor shows warning: "This file belongs to main-api"
   - Options: Open read-only, request ownership, cancel

4. AI in Window 2 can read `../../index.js` for context
   - Full understanding of main API service
   - Can provide relevant suggestions
   - Cannot edit the file

---

## Technical Considerations

### Performance
- **Caching**: Dependency graphs are cached to avoid repeated file system reads
- **Lazy Loading**: Dependency files are loaded on-demand, not all at once
- **Efficient Checks**: Ownership checks are optimized to minimize overhead
- **Minimal Impact**: File operations have minimal performance overhead

### Edge Cases
- **Circular Dependencies**: Detected and warned about (e.g., Project A depends on B, B depends on A)
- **Symlinks**: Resolved correctly to actual file paths
- **Network Drives**: Ownership checks work across network-mounted drives
- **External Edits**: Handles files edited outside of Cursor gracefully

### Backward Compatibility
- **Works Without Configuration**: Feature works without `.cursorproject` files (default behavior)
- **Existing Workflows**: All existing Cursor workflows continue to work unchanged
- **Opt-In Feature**: Can be enabled/disabled per project or globally
- **Gradual Adoption**: Teams can adopt the feature incrementally

---

## Alternative Approaches Considered

### 1. File-Level Permissions
**Why not:** Too granular and hard to manage. Would require setting permissions for every file individually, which doesn't solve the root problem of project-level ownership.

### 2. Workspace-Level Only
**Why not:** Doesn't handle dependencies between projects. No automatic parent-child resolution, which is a key use case.

### 3. Git-Based
**Why not:** Requires git to be present, which isn't always available. Also doesn't solve real-time conflicts - only helps with committed changes.

---

## Success Metrics

How we'll know this feature is successful:

1. **Reduced Conflicts**: Zero file conflicts when using ownership system
2. **Improved Workflow**: Developers can confidently use multiple windows without fear of conflicts
3. **Better AI Context**: AI understands relationships across projects and provides better suggestions
4. **Adoption**: Feature is actively used by developers working with monorepos and related projects

---

## Conclusion

This feature would significantly improve the developer experience when working with monorepos and related projects. It solves a real problem with an elegant solution that maintains full AI context while preventing file conflicts.

The implementation is straightforward, builds on existing Cursor infrastructure, and provides clear benefits for developers working with complex project structures.

---

## Feature Details

**Feature Category**: Editor / Multi-Window / Project Management

**Priority**: High (solves real workflow problem)

**Complexity**: Medium (requires ownership tracking and dependency resolution)

**Dependencies**: None (can be implemented incrementally)

**Breaking Changes**: None (opt-in feature)
