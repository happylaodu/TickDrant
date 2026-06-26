//
//  CompletedTaskRowView.swift
//  Tickdrant
//
//  Display a single completed task in the "Completed" tab.
//

import SwiftUI

struct CompletedTaskRowView: View {
    let task: DueTask

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("✓ \(task.name)")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 80.0/255.0, green: 80.0/255.0, blue: 80.0/255.0))
                Spacer()
                Text("Importance: \(task.effectiveImportance)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            HStack {
                Spacer()
                Text(infoText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 0.94, green: 1.0, blue: 0.94))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 100.0/255.0, green: 200.0/255.0, blue: 100.0/255.0), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var infoText: String {
        var parts: [String] = []
        if task.dueDateTime != nil {
            parts.append("Was due: \(task.dueDateTimeString)")
        }
        parts.append("Completed: \(task.completedDateTimeString)")
        if let label = punctualityLabel {
            parts.append(label)
        }
        return parts.joined(separator: " · ")
    }

    /// "Completed X days early" / "Completed X days overdue" — Java Idea-4 (2026-04-19)
    private var punctualityLabel: String? {
        guard let due = task.dueDateTime, let completed = task.completedDateTime else { return nil }
        let seconds = due.timeIntervalSince(completed)
        let days = Int(seconds / 86400.0)
        if days > 0 {
            return "Completed \(days) day\(days == 1 ? "" : "s") early"
        } else if days < 0 {
            let overdue = -days
            return "Completed \(overdue) day\(overdue == 1 ? "" : "s") overdue"
        }
        return "Completed on time"
    }
}
