# Ideas

## Ideas

- **Idea-15** (2026-06-26): [Config] Prepare App Store Connect listing and submission package
  - Create App ID `com.happylaodu.tickdrant` in Apple Developer portal
  - In App Store Connect: app name (Tickdrant), subtitle, description, keywords, support URL, marketing URL
  - Privacy Policy URL (even though no data is collected — App Store still requires one)
  - Fill App Privacy section ("Data Not Collected")
  - Prepare 4–10 screenshots (1280×800 or higher for macOS)
  - Set pricing & availability, age rating
  - Archive build with Release configuration, validate, upload via Xcode Organizer
  - Submit for review

- **Idea-14** (2026-06-26): [Localization] Add Chinese (Simplified) localization
  - Add `zh-Hans` to project supported languages
  - Use String Catalog (`.xcstrings`) — already enabled via `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`
  - Translate all user-facing strings in SettingsView, TaskEditView, TaskRowView, QuadrantView, ContentView, MenuBarManager menu items
  - Verify date/time formatting respects locale

- **Idea-13** (2026-06-26): [Improvement] Refactor AppDelegate window-finding logic
  - Current code in `TickdrantApp.swift` uses a 0.5s `Timer` polling loop to find the main window
  - Fragile; could fail or bind to wrong window in edge cases
  - Replace with `NSApplication.didBecomeActiveNotification` / `NSWindow.didBecomeMainNotification` observers, or use SwiftUI's `WindowGroup` `windowToolbarStyle` + scene phase tracking
  - Goal: deterministic main-window reference without polling

- **Idea-10** (2026-06-19): [Feature] Show red badge on menu bar icon for tasks nearing due date
  - When tasks are approaching their due dates, display a small red numeric badge on the menu bar icon
  - Badge shows the count of tasks that are due soon (or overdue)
  - Helps users notice urgent tasks without opening the app
  - Need to define the threshold for "nearing due" (e.g., overdue + due within X hours/days)

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

- **Idea-8** (2026-03-08): [Feature] Add data export and import functionality - ✅ Completed 2026-06-26
  - ✅ `TaskManager`: added `exportTasks(to:)` (ISO8601 dates) and `importTasks(from:mode:)` with `.merge` (UUID-dedupe) and `.replace` modes; invalid JSON throws `ImportError.invalidFormat` without mutating existing data
  - ✅ `SettingsView`: new "Data" section with Export Tasks… / Import Tasks… buttons; uses `NSSavePanel` / `NSOpenPanel`; default filename `tickdrant-tasks-YYYYMMDD.json`
  - ✅ Import flow: 3-button alert (Merge / Replace All / Cancel) with summary alert reporting added vs skipped counts
  - ✅ `TickdrantApp`: injected `taskManager` into Settings scene environment
  - ✅ Removed misleading static data-location text from About section (sandbox container path was incorrect)
  - ⚠️ Side note (also today): Bundle ID change `com.tickdrant` → `com.happylaodu.tickdrant` moved the sandbox container; one-time manual migration of `tasks.json` + UserDefaults plist from old to new container was needed. User backed up via the new Export feature afterwards.

- **Idea-11** (2026-06-26): [Documentation] Update README to reflect sandbox reality - ✅ Completed 2026-07-04
  - ✅ Replaced misleading static path in Features bullet with guidance to use Settings → Data → Export / Import
  - ✅ Rewrote "Data Storage" section: notes App Sandbox container is private, points users at Export/Import for backup and migration
  - ✅ No stale Bundle ID references remained in README

- **Idea-12** (2026-06-26): [Improvement] Clean up debug `print()` statements before release - ✅ Completed 2026-07-01
  - ✅ Introduced `os.Logger` (subsystem `com.happylaodu.tickdrant`) with per-file categories
  - ✅ Replaced 15 informational prints in `TickdrantApp.swift` with `Self.logger.debug` (static logger inside `AppDelegate` — file-scope `let` conflicts with `@main`)
  - ✅ Replaced 3 prints in `MenuBarManager.swift` with `logger.debug` (file-scope)
  - ✅ Replaced 2 error prints in `TaskManager.swift` with `logger.error(...localizedDescription, privacy: .public)`
  - ✅ Replaced 2 error prints in `SettingsManager.swift` with `logger.error(...)`
  - ✅ Release builds now silent by default; errors still surface via unified logging
  - ✅ Verified with `xcodebuild ... build` (Debug, macOS) → BUILD SUCCEEDED

- **Idea-2** (2026-03-08): [Config] Set up source control with Git - ✅ Completed 2026-06-26
  - ✅ Git repository already initialized (branch `main`)
  - ✅ `.gitignore` already in place (Xcode, Swift, macOS, plus `.claude/settings.local.json`)
  - ✅ Created initial commit `3e36485` with all source code (34 files, 3324 insertions)
  - ✅ Added remote `origin` → `git@github.com:happylaodu/TickDrant.git` and pushed `main`

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
