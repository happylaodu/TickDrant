//
//  TaskManager.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import Foundation
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [DueTask] = []

    private let saveURL: URL
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var cancellables = Set<AnyCancellable>()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("Tickdrant", isDirectory: true)
        // One-time migration from the pre-rename "DueDateAssistant" directory.
        let legacyDirectory = appSupport.appendingPathComponent("DueDateAssistant", isDirectory: true)
        let fm = FileManager.default
        if fm.fileExists(atPath: legacyDirectory.path) && !fm.fileExists(atPath: appDirectory.path) {
            try? fm.moveItem(at: legacyDirectory, to: appDirectory)
        }
        try? fm.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        saveURL = appDirectory.appendingPathComponent("tasks.json")

        loadTasks()

        timer.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }

    // MARK: - Computed Lists

    var activeTasks: [DueTask] {
        tasks.filter { !$0.completed }
    }

    var completedTasks: [DueTask] {
        tasks.filter { $0.completed }
            .sorted { ($0.completedDateTime ?? .distantPast) > ($1.completedDateTime ?? .distantPast) }
    }

    /// Active tasks sorted by Eisenhower quadrant priority (Q1 > Q2 > Q3 > Q4),
    /// then by due-date / importance within each quadrant.
    var quadrantSortedActiveTasks: [DueTask] {
        let now = Date()
        return activeTasks.sorted { compareByQuadrant($0, $1, now: now) }
    }

    private func compareByQuadrant(_ a: DueTask, _ b: DueTask, now: Date) -> Bool {
        let qa = a.quadrant(now: now).rawValue
        let qb = b.quadrant(now: now).rawValue
        if qa != qb { return qa < qb }

        switch qa {
        case 1, 3:
            // Urgent quadrants: sort by due date ascending (most urgent first)
            let da = a.dueDateTime ?? .distantFuture
            let db = b.dueDateTime ?? .distantFuture
            return da < db
        default:
            // Non-urgent quadrants: sort by importance desc, then due date
            if a.effectiveImportance != b.effectiveImportance {
                return a.effectiveImportance > b.effectiveImportance
            }
            // Tasks without due date go after tasks with due date
            switch (a.dueDateTime, b.dueDateTime) {
            case (nil, nil): return false
            case (nil, _):   return false
            case (_, nil):   return true
            case let (.some(da), .some(db)): return da < db
            }
        }
    }

    // MARK: - CRUD

    func addTask(_ task: DueTask) {
        tasks.append(task)
        saveTasks()
    }

    func updateTask(_ task: DueTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }

    func deleteTask(_ task: DueTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    /// Mark a task as completed (moves it to the Completed list).
    func completeTask(_ task: DueTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].markAsCompleted()
            saveTasks()
        }
    }

    /// For overdue recurring tasks: advance to next occurrence without marking completed.
    func completeAndNext(_ task: DueTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].moveToNextOccurrence()
            saveTasks()
        }
    }

    // MARK: - Persistence

    private func saveTasks() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(tasks)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Failed to save tasks: \(error)")
        }
    }

    private func loadTasks() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            tasks = try JSONDecoder().decode([DueTask].self, from: data)
        } catch {
            print("Failed to load tasks: \(error)")
        }
    }
}
