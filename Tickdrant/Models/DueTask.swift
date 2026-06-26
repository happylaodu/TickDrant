//
//  DueTask.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import Foundation

struct DueTask: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var dueDateTime: Date?
    var importance: Int?
    var isRecurring: Bool
    var recurrenceValue: Int
    var recurrenceUnit: RecurrenceUnit
    var completed: Bool
    var completedDateTime: Date?

    enum RecurrenceUnit: String, Codable, CaseIterable {
        case hours = "Hours"
        case days = "Days"
        case weeks = "Weeks"
        case months = "Months"
        case years = "Years"

        var calendarComponent: Calendar.Component {
            switch self {
            case .hours: return .hour
            case .days: return .day
            case .weeks: return .weekOfYear
            case .months: return .month
            case .years: return .year
            }
        }

        func displayName(value: Int) -> String {
            let base: String
            switch self {
            case .hours: base = "hour"
            case .days: base = "day"
            case .weeks: base = "week"
            case .months: base = "month"
            case .years: base = "year"
            }
            return value == 1 ? base : base + "s"
        }
    }

    init(id: UUID = UUID(),
         name: String,
         dueDateTime: Date? = nil,
         importance: Int? = nil,
         isRecurring: Bool = false,
         recurrenceValue: Int = 1,
         recurrenceUnit: RecurrenceUnit = .days,
         completed: Bool = false,
         completedDateTime: Date? = nil) {
        self.id = id
        self.name = name
        self.dueDateTime = dueDateTime
        self.importance = importance
        self.isRecurring = isRecurring
        self.recurrenceValue = recurrenceValue
        self.recurrenceUnit = recurrenceUnit
        self.completed = completed
        self.completedDateTime = completedDateTime
    }

    // Backward-compatible decoding for older tasks.json without new fields
    private enum CodingKeys: String, CodingKey {
        case id, name, dueDateTime, importance, isRecurring
        case recurrenceValue, recurrenceUnit, completed, completedDateTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try c.decode(String.self, forKey: .name)
        self.dueDateTime = try c.decodeIfPresent(Date.self, forKey: .dueDateTime)
        self.importance = try c.decodeIfPresent(Int.self, forKey: .importance)
        self.isRecurring = try c.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
        self.recurrenceValue = try c.decodeIfPresent(Int.self, forKey: .recurrenceValue) ?? 1
        self.recurrenceUnit = try c.decodeIfPresent(RecurrenceUnit.self, forKey: .recurrenceUnit) ?? .days
        self.completed = try c.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        self.completedDateTime = try c.decodeIfPresent(Date.self, forKey: .completedDateTime)
    }

    var effectiveImportance: Int {
        importance ?? 3
    }

    var isOverdue: Bool {
        guard let due = dueDateTime else { return false }
        return due < Date()
    }

    var timeRemaining: TimeInterval? {
        guard let due = dueDateTime else { return nil }
        return due.timeIntervalSinceNow
    }

    mutating func moveToNextOccurrence() {
        guard isRecurring, let due = dueDateTime else { return }

        let calendar = Calendar.current
        var newDate = due
        let now = Date()

        // Always advance at least one period, then keep advancing until in the future.
        // This makes "Complete & Next" work the same for overdue and non-overdue tasks.
        repeat {
            newDate = calendar.date(byAdding: recurrenceUnit.calendarComponent,
                                    value: recurrenceValue,
                                    to: newDate) ?? newDate
        } while newDate <= now

        dueDateTime = newDate
    }

    mutating func markAsCompleted() {
        completed = true
        completedDateTime = Date()
    }

    var recurrenceDescription: String {
        guard isRecurring else { return "" }
        return "Every \(recurrenceValue) \(recurrenceUnit.displayName(value: recurrenceValue))"
    }

    var dueDateTimeString: String {
        guard let date = dueDateTime else { return "No due date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    var completedDateTimeString: String {
        guard let date = completedDateTime else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Eisenhower Quadrant Logic

enum Quadrant: Int {
    case q1 = 1  // Important & Urgent (Red, Top-Right)
    case q2 = 2  // Important & Not Urgent (Green, Top-Left)
    case q3 = 3  // Not Important & Urgent (Orange, Bottom-Right)
    case q4 = 4  // Not Important & Not Urgent (Gray, Bottom-Left)
}

struct QuadrantConfig {
    static let urgencyThresholdDays: Double = 5.0
    static let importanceThreshold: Int = 5
}

extension DueTask {
    func isImportant() -> Bool {
        effectiveImportance >= QuadrantConfig.importanceThreshold
    }

    func isUrgent(now: Date = Date()) -> Bool {
        guard let due = dueDateTime else { return false }
        let days = due.timeIntervalSince(now) / 86400.0
        return days < QuadrantConfig.urgencyThresholdDays
    }

    func quadrant(now: Date = Date()) -> Quadrant {
        let important = isImportant()
        if dueDateTime == nil {
            return important ? .q2 : .q4
        }
        let urgent = isUrgent(now: now)
        switch (important, urgent) {
        case (true, true):  return .q1
        case (true, false): return .q2
        case (false, true): return .q3
        case (false, false): return .q4
        }
    }
}
