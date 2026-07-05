//
//  TaskManager.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import Foundation
import Combine
import os

private let logger = Logger(subsystem: "com.brightjune.Tickdrant", category: "TaskManager")

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

    // MARK: - Export / Import

    enum ImportMode {
        case replace
        case merge
    }

    struct ImportResult {
        let added: Int
        let skipped: Int
        let totalInFile: Int
    }

    enum ImportError: LocalizedError {
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "The selected file is not a valid Tickdrant tasks file."
            }
        }
    }

    func exportTasks(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(tasks)
        try data.write(to: url, options: .atomic)
    }

    func importTasks(from url: URL, mode: ImportMode) throws -> ImportResult {
        let data = try Data(contentsOf: url)

        // Try ISO8601 first (export format), then fall back to default (legacy in-app format).
        let imported: [DueTask]
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            imported = try decoder.decode([DueTask].self, from: data)
        } catch {
            do {
                imported = try JSONDecoder().decode([DueTask].self, from: data)
            } catch {
                throw ImportError.invalidFormat
            }
        }

        switch mode {
        case .replace:
            tasks = imported
            saveTasks()
            return ImportResult(added: imported.count, skipped: 0, totalInFile: imported.count)
        case .merge:
            let existingIDs = Set(tasks.map(\.id))
            let newTasks = imported.filter { !existingIDs.contains($0.id) }
            tasks.append(contentsOf: newTasks)
            saveTasks()
            return ImportResult(added: newTasks.count,
                                skipped: imported.count - newTasks.count,
                                totalInFile: imported.count)
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
            logger.error("Failed to save tasks: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadTasks() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            tasks = try JSONDecoder().decode([DueTask].self, from: data)
        } catch {
            logger.error("Failed to load tasks: \(error.localizedDescription, privacy: .public)")
        }
    }
}
