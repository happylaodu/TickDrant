# Tickdrant - Project Context

## Project Overview

**Tickdrant** (formerly *Due-Date Assistant*; bundle id `com.tickdrant`) is a native macOS countdown timer application built with Swift and SwiftUI. It's a complete rewrite of the original Java-based countdown_timer application, offering better performance, smaller app size, and seamless macOS integration.

## Project Origin

- **Original Project**: Java-based countdown timer (located at `~/Library/CloudStorage/OneDrive-TrendMicro/Learning/java/countdown_timer/`)
- **Migration Date**: 2026-03-08
- **Reason for Rewrite**: Native macOS experience, better performance, Universal Binary support, and modern SwiftUI architecture
- **Related Idea**: Idea-12 from original project's Ideas.md

## Key Features

1. **Task Management**
   - Add new countdown tasks with name and due date/time
   - Edit existing tasks (name, due date, recurrence settings)
   - Delete tasks with confirmation dialog
   - Click to select/deselect tasks

2. **Recurring Tasks**
   - Support for recurring intervals: Hours, Days, Weeks, Months, Years
   - Custom recurrence values (1-999)
   - Visual indicator (🔄 emoji)
   - "Complete & Next" button for overdue recurring tasks
   - Automatic calculation of next occurrence

3. **Real-time Display**
   - Live countdown updates every second
   - Format: "X days, HH:MM:SS" or "HH:MM:SS"
   - Auto-sorting by due date/time (earliest first)
   - Visual states: Normal, Selected, Overdue

4. **Data Persistence**
   - Storage location: `~/Library/Application Support/Tickdrant/tasks.json` (legacy `DueDateAssistant/` directory is auto-migrated on first launch)
   - Format: JSON (easy migration and backup)
   - Auto-save on add/edit/delete operations
   - Auto-load on app launch (includes overdue tasks)

## Technical Architecture

### Technology Stack
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Deployment Target**: macOS 13.0+
- **Build System**: Xcode 15.0+
- **Architecture Pattern**: MVVM (Model-View-ViewModel)

### Project Structure

```
Tickdrant/
├── TickdrantApp.swift              # App entry point (@main)
├── Models/
│   └── DueTask.swift              # Task data model (Codable, Identifiable)
├── ViewModels/
│   └── TaskManager.swift          # Business logic, data persistence, timer
├── Views/
│   ├── ContentView.swift          # Main window with task list
│   ├── TaskRowView.swift          # Individual task display component
│   └── TaskEditView.swift         # Add/Edit dialog (modal sheet)
├── Assets.xcassets/
│   ├── AppIcon.appiconset/        # App icon (placeholder)
│   └── Contents.json
├── Info.plist                      # App configuration
└── Tickdrant.entitlements          # Sandbox permissions
```

### Key Components

#### DueTask Model
- Properties: id, name, dueDateTime, isRecurring, recurrenceValue, recurrenceUnit
- Methods: moveToNextOccurrence(), computed properties (isOverdue, timeRemaining)
- Conforms to: Identifiable, Codable, Equatable

#### TaskManager (ViewModel)
- Manages task list (@Published property)
- Handles CRUD operations (add, update, delete, complete)
- Timer-based UI refresh (every 1 second via Combine)
- JSON persistence (save/load to Application Support)

#### UI Components
- **ContentView**: Main window (467x650), toolbar, scrollable task list, empty state
- **TaskRowView**: Task display with selection, edit/delete buttons, visual states
- **TaskEditView**: Modal dialog for add/edit with validation

## UI Design Specifications

### Window
- **Size**: 467x650 pixels (fixed)
- **Style**: Hidden title bar
- **Resizability**: Content size only

### Visual States
- **Normal Task**: Gray border (1px), white background
- **Selected Task**: Blue border (3px), light blue background (#E6F0FF)
- **Overdue Task**: Red border (2px), light red background (#FFF0F0)

### Task Display Elements
- Task name (bold, 16pt) with 🔄 for recurring tasks
- Countdown timer or "Time's up! [OVERDUE]" message
- Recurrence info: "Every X day(s) · Due: YYYY-MM-DD HH:mm"
- Due date/time at bottom right (gray, 12pt)
- Edit/Delete/Complete buttons (shown when selected)

## Data Model

### Task Storage Format (JSON)
```json
[
  {
    "id": "UUID-string",
    "name": "Task name",
    "dueDateTime": "2026-03-10T15:30:00Z",
    "isRecurring": true,
    "recurrenceValue": 7,
    "recurrenceUnit": "days"
  }
]
```

### Recurrence Units
- hours → Calendar.Component.hour
- days → Calendar.Component.day
- weeks → Calendar.Component.weekOfYear
- months → Calendar.Component.month
- years → Calendar.Component.year

## User Workflows

### Add Task
1. Click "+ Add Task" button
2. Enter task name (required, non-empty)
3. Select due date/time (must be in future for new tasks)
4. Optionally configure recurrence (checkbox + value + unit)
5. Click "Add" → Validates → Saves → Updates display

### Edit Task
1. Click on task to select it
2. Click "Edit" button
3. Modify fields in dialog (pre-populated with current values)
4. Click "Save" → Validates → Updates → Saves

### Delete Task
1. Click on task to select it
2. Click "Delete" button
3. Confirm in dialog
4. Task removed and data saved

### Complete Recurring Task (Overdue)
1. Task becomes overdue (red highlight)
2. "Complete" button appears instead of "Delete"
3. Click "Complete" → Moves to next occurrence after current time
4. Updates display and saves

## Validation Rules

1. **Task Name**: Must not be empty (trimmed whitespace)
2. **Due Date**: Must be in future (for new tasks or editing non-overdue tasks)
3. **Recurrence Value**: Must be between 1 and 999 (if recurring enabled)

## Comparison with Java Version

### Advantages
- ✅ Native performance (no JVM overhead)
- ✅ Smaller app size (~few MB vs ~80MB with JRE)
- ✅ Universal Binary (Intel + Apple Silicon)
- ✅ Native date/time pickers (no external library needed)
- ✅ Modern SwiftUI animations and transitions
- ✅ Better macOS integration (App Sandbox, Launch Services)
- ✅ Cleaner, more maintainable code (SwiftUI declarative syntax)

### Feature Parity
- ✅ All features from Java version implemented
- ✅ Same window size (467x650)
- ✅ Same visual design (colors, borders, layout)
- ✅ Same task management capabilities
- ✅ Same recurring task logic

### Differences
- **Data Format**: JSON instead of Java Serialization (better portability)
- **Storage Location**: Different directory (Tickdrant vs CountdownTimer)
- **No Migration Tool**: Existing Java app data not auto-imported

## Build & Run

### Development
```bash
# Open in Xcode
open Tickdrant.xcodeproj

# Or use command line
xcodebuild -project Tickdrant.xcodeproj -scheme Tickdrant build

# Run
./run.sh
```

### Distribution
- Build target: Debug (for development)
- Code signing: Automatic (local development)
- App Sandbox: Enabled
- Deployment: Manual (drag to /Applications)

## Future Enhancement Ideas

See `.claude/Ideas.md` for potential improvements such as:
- Menu bar integration
- Notification support
- Custom app icon
- Export/import tasks
- Widgets for macOS
- iCloud sync
- Accessibility improvements
- Localization support

## Related Files

- **Original Java Project**: `~/Library/CloudStorage/OneDrive-TrendMicro/Learning/java/countdown_timer/`
- **Original Ideas**: `~/Library/CloudStorage/OneDrive-TrendMicro/Learning/java/countdown_timer/.claude/Ideas.md`
- **Data Storage**: `~/Library/Application Support/Tickdrant/tasks.json`

## Development Notes

- Project created: 2026-03-08
- Swift version: 5.0
- Xcode version: 15.0+
- macOS deployment target: 13.0+
- Build status: ✅ Compiles successfully
- App bundle identifier: com.tickdrant
