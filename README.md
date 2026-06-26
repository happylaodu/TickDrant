# Tickdrant

A native macOS countdown timer application built with Swift and SwiftUI. Rewritten from the original Java version for better performance and native macOS integration.

## Features

- **Task Management**: Add, edit, and delete countdown tasks
- **Real-time Countdown**: Live countdown display updating every second
- **Recurring Tasks**: Support for recurring tasks with customizable intervals (hours, days, weeks, months, years)
- **Overdue Handling**: Visual indicators for overdue tasks with completion options for recurring tasks
- **Auto-sorting**: Tasks automatically sorted by due date/time
- **Data Persistence**: Tasks saved to `~/Library/Application Support/Tickdrant/tasks.json`
- **Native macOS UI**: Built with SwiftUI for optimal macOS experience

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later

## Building

1. Open `Tickdrant.xcodeproj` in Xcode
2. Select the Tickdrant scheme
3. Build and run (⌘R)

## Usage

1. Click "+ Add Task" to create a new task
2. Enter task name, due date/time, and optional recurrence settings
3. Tasks display with real-time countdown
4. Click on a task to select it and show Edit/Delete buttons
5. Overdue recurring tasks show "Complete" button to move to next occurrence

## Task Display

- **Normal**: Gray border, white background
- **Selected**: Blue border (3px), light blue background
- **Overdue**: Red border (2px), light red background with "[OVERDUE]" tag
- **Recurring**: 🔄 indicator with interval description

## Data Storage

Tasks are stored as JSON in:
```
~/Library/Application Support/Tickdrant/tasks.json
```

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Clear separation of concerns
- **Combine Framework**: Reactive updates for real-time countdown
- **Codable**: JSON serialization for data persistence

## Project Structure

```
Tickdrant/
├── TickdrantApp.swift          # App entry point
├── Models/
│   └── DueTask.swift           # Task data model
├── ViewModels/
│   └── TaskManager.swift       # Business logic & data management
├── Views/
│   ├── ContentView.swift       # Main view
│   ├── TaskRowView.swift       # Task display component
│   └── TaskEditView.swift      # Add/Edit dialog
└── Assets.xcassets/            # App icon and assets
```

## Differences from Java Version

- **Native Performance**: Swift provides better performance and smaller app size
- **Modern UI**: SwiftUI offers more fluid animations and native macOS feel
- **Universal Binary**: Built-in support for Intel and Apple Silicon
- **Better Integration**: Seamless integration with macOS features
- **Simpler Codebase**: SwiftUI reduces UI code complexity significantly

## License

Copyright © 2026. All rights reserved.
