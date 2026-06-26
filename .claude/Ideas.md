# Ideas

## Ideas

- **Idea-10** (2026-06-19): [Feature] Show red badge on menu bar icon for tasks nearing due date
  - When tasks are approaching their due dates, display a small red numeric badge on the menu bar icon
  - Badge shows the count of tasks that are due soon (or overdue)
  - Helps users notice urgent tasks without opening the app
  - Need to define the threshold for "nearing due" (e.g., overdue + due within X hours/days)

- **Idea-8** (2026-03-08): [Feature] Add data export and import functionality
  - Export tasks to JSON file for backup
  - Import tasks from JSON file
  - Add Export/Import buttons in Settings or File menu
  - Support merging imported tasks with existing ones
  - Validate JSON format during import

- **Idea-7** (2026-03-08): [Feature] Add notification system for task reminders
  - Implement local notifications before tasks are due
  - Support configurable reminder times (5 minutes, 1 hour, 1 day before)
  - Request notification permissions from user
  - Allow users to enable/disable notifications per task
  - Show notification with task name and remaining time

- **Idea-6** (2026-03-08): [UX] Replace Edit/Delete buttons with icons
  - Replace text-based "Edit" and "Delete" buttons with icon buttons
  - Use SF Symbols (pencil for edit, trash for delete)
  - Make UI more compact and visually appealing
  - Ensure icons are clear and accessible

- **Idea-4** (2026-03-08): [Feature] Multi-user collaboration via online document
  - Support sharing task data through online document storage (e.g., Google Drive, OneDrive, Dropbox)
  - Multiple users can share the same task list and see each other's due date tasks
  - Sync data automatically when app launches or periodically
  - Handle potential conflicts when multiple users edit simultaneously

- **Idea-3** (2026-03-08): [Feature] Add comment field to tasks
  - Add optional comment/note field to tasks for additional context or details
  - Display in task edit/add dialogs as multi-line text area
  - Show comment in task panel (e.g., below task name or in tooltip)
  - Save/load comments with task data

- **Idea-2** (2026-03-08): [Config] Set up source control with Git
  - Initialize Git repository for the project
  - Create .gitignore file to exclude build artifacts, IDE files, and temporary files (already exists)
  - Make initial commit with current source code
  - Consider adding remote repository (GitHub/GitLab) for backup and collaboration

<!-- Add new ideas here -->

## Completed

### Migration from Java Version (2026-03-08)

This Swift app is a complete rewrite of the original Java countdown timer application. All features from the Java version have been successfully implemented:

- ✅ Task management (add, edit, delete)
- ✅ Real-time countdown display
- ✅ Recurring tasks with customizable intervals (hours, days, weeks, months, years)
- ✅ Overdue task handling with visual indicators
- ✅ Auto-sorting by due date/time
- ✅ Data persistence (JSON format)
- ✅ Task selection system
- ✅ Native macOS UI with SwiftUI

Additional improvements over Java version:
- ✅ Better performance (native Swift, no JVM)
- ✅ Smaller app size
- ✅ Universal Binary (Intel + Apple Silicon)
- ✅ Modern SwiftUI architecture
- ✅ JSON data format (more portable than Java serialization)
- ✅ Data migration tool created for importing Java tasks

---

- **Idea-1** (2026-03-08): [Feature] Allow user to choose app display location (Dock, menu bar, or both) - ✅ Completed 2026-03-08
  - ✅ Created MenuBarManager.swift for menu bar management
  - ✅ Implemented menu bar icon with clock symbol
  - ✅ Display next upcoming task in menu bar menu
  - ✅ Added "Show Main Window" and "Settings" menu items
  - ✅ Control app activation policy based on DisplayLocation setting:
    - Dock Only: .regular (appears in Dock)
    - Menu Bar Only: .accessory (menu bar only, no Dock icon)
    - Both: .regular + menu bar (appears in both)
  - ✅ Settings change triggers immediate update of display location
  - ✅ Menu updates every minute with latest task countdown

- **Idea-9** (2026-06-14): [Improvement] Split recurring task action into two types - ✅ Completed 2026-06-19
  - ✅ Updated `moveToNextOccurrence` to advance one period even when not overdue (so "Complete & Next" works for both overdue and non-overdue recurring tasks)
  - ✅ `TaskRowView`: recurring tasks now show two distinct buttons — **Complete & Next** (green) and **End Series** (orange) — both available when overdue or selected
  - ✅ `TaskRowView` context menu: for recurring tasks, replaced single "Complete" with "Complete & Next Occurrence" and "End Recurring Series"
  - ✅ `QuadrantView` `TaskBoxView` context menu: same split for recurring tasks
  - ✅ Wired `onCompleteAndNext` through `QuadrantView` → `ContentView` → `TaskManager.completeAndNext`
  - ✅ Tooltips on row buttons clarify intent (advance to next due vs. end series entirely)

- **Idea-5** (2026-03-08): [Feature] Add Settings window with basic preferences - ✅ Completed 2026-03-08
  - ✅ Created SettingsView.swift with settings UI
  - ✅ Created SettingsManager.swift for managing preferences
  - ✅ Implemented launch at login with ServiceManagement API
  - ✅ Added notification permissions toggle with request button
  - ✅ Added display location setting (Dock/Menu Bar/Both)
  - ✅ Settings saved to UserDefaults
  - ✅ Integrated Settings window into app (⌘, to open)
  - ✅ Added About section with version and data location info
  - ✅ Added gear icon in main UI to open Settings

<!-- Completed ideas will be moved here with timestamps -->

## Rejected

<!-- Rejected ideas will be moved here with reasons -->
