//
//  ContentView.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var menuBarManager: MenuBarManager
    @Environment(\.openWindow) private var openWindow
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var selectedTask: DueTask?
    @State private var editingTask: DueTask?
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ZStack {
                Button(action: {
                    editingTask = nil
                    showingAddTask = true
                }) {
                    Label("Add Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                HStack {
                    Spacer()
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            // Tab selector — placed directly below the Add Task button,
            // matching the original Java app's layout.
            Picker("", selection: $selectedTab) {
                Text("Four Quadrants").tag(0)
                Text("Task List").tag(1)
                Text("Completed").tag(2)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 360)
            .padding(.bottom, 8)

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case 0: quadrantTab
                case 1: taskListTab
                case 2: completedTab
                default: EmptyView()
                }
            }
            .padding(8)
        }
        .frame(minWidth: 850, minHeight: 680)
        .sheet(isPresented: $showingAddTask, onDismiss: {
            editingTask = nil
        }) {
            TaskEditView(task: editingTask) { newTask in
                if editingTask != nil {
                    taskManager.updateTask(newTask)
                } else {
                    taskManager.addTask(newTask)
                }
                editingTask = nil
                selectedTask = nil
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(menuBarManager: menuBarManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerSettingsSheet"))) { _ in
            showingSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowAbout"))) { _ in
            openWindow(id: "about")
        }
    }

    // MARK: - Tabs

    private var quadrantTab: some View {
        QuadrantView(
            selectedTask: $selectedTask,
            onEdit: { task in
                editingTask = task
                showingAddTask = true
            },
            onComplete: { task in
                withAnimation { taskManager.completeTask(task) }
            },
            onCompleteAndNext: { task in
                withAnimation { taskManager.completeAndNext(task) }
            },
            onDelete: { task in
                withAnimation { taskManager.deleteTask(task) }
            }
        )
        .environmentObject(taskManager)
    }

    private var taskListTab: some View {
        Group {
            if taskManager.activeTasks.isEmpty {
                emptyState(message: "No active tasks", hint: "Click '+ Add Task' to get started")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(taskManager.quadrantSortedActiveTasks) { task in
                            TaskRowView(
                                task: task,
                                isSelected: selectedTask?.id == task.id,
                                onSelect: {
                                    selectedTask = selectedTask?.id == task.id ? nil : task
                                },
                                onEdit: {
                                    editingTask = task
                                    showingAddTask = true
                                },
                                onDelete: {
                                    withAnimation {
                                        taskManager.deleteTask(task)
                                        if selectedTask?.id == task.id { selectedTask = nil }
                                    }
                                },
                                onComplete: {
                                    withAnimation {
                                        taskManager.completeTask(task)
                                        if selectedTask?.id == task.id { selectedTask = nil }
                                    }
                                },
                                onCompleteAndNext: {
                                    withAnimation {
                                        taskManager.completeAndNext(task)
                                        if selectedTask?.id == task.id { selectedTask = nil }
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var completedTab: some View {
        Group {
            if taskManager.completedTasks.isEmpty {
                emptyState(message: "No completed tasks yet",
                           hint: "Completed tasks will appear here")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(taskManager.completedTasks) { task in
                            CompletedTaskRowView(task: task)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func emptyState(message: String, hint: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(message)
                .font(.title2)
                .foregroundColor(.secondary)
            Text(hint)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
