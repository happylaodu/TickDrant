//
//  TaskRowView.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import SwiftUI

struct TaskRowView: View {
    let task: DueTask
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onComplete: () -> Void
    let onCompleteAndNext: () -> Void

    @State private var showDeleteConfirmation = false

    private var quadrant: Quadrant { task.quadrant() }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Task name
                    HStack(spacing: 4) {
                        Text(task.name)
                            .font(.system(size: 16, weight: .bold))
                        if task.isRecurring {
                            Text("🔄")
                        }
                    }

                    // Countdown / overdue / no due date
                    if task.dueDateTime == nil {
                        Text("No due date")
                            .font(.system(size: 18, weight: .regular))
                            .italic()
                            .foregroundColor(.secondary)
                    } else if task.isOverdue {
                        HStack {
                            Text("Time's up!")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                            Text("[OVERDUE]")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red)
                        }
                    } else if let remaining = task.timeRemaining {
                        Text(formatCountdown(remaining))
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                // Action buttons
                HStack(spacing: 6) {
                    if task.isRecurring && (task.isOverdue || isSelected) {
                        Button(action: onCompleteAndNext) {
                            Text("Complete & Next")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.bordered)
                        .help("Mark this occurrence done and advance to the next due date")

                        Button(action: onComplete) {
                            Text("End Series")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.bordered)
                        .help("End the entire recurring series (no more occurrences)")
                    } else if !task.isRecurring && isSelected {
                        Button(action: onComplete) {
                            Text("Complete")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.bordered)
                    }

                    if isSelected {
                        Button(action: { showDeleteConfirmation = true }) {
                            Text("Delete")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            // Bottom info: importance + due date
            HStack {
                Spacer()
                Text(infoText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onEdit()
        }
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            if task.isRecurring {
                Button(action: onCompleteAndNext) {
                    Label("Complete & Next Occurrence", systemImage: "arrow.forward.circle")
                }
                Button(action: onComplete) {
                    Label("End Recurring Series", systemImage: "checkmark.circle")
                }
            } else {
                Button(action: onComplete) {
                    Label("Complete", systemImage: "checkmark.circle")
                }
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete '\(task.name)'?")
        }
    }

    private var infoText: String {
        var parts: [String] = ["Importance: \(task.effectiveImportance)"]
        if task.dueDateTime != nil {
            if task.isRecurring {
                let unitName = task.recurrenceUnit.displayName(value: task.recurrenceValue)
                parts.append("Every \(task.recurrenceValue) \(unitName)")
                parts.append("Due: \(task.dueDateTimeString)")
            } else {
                parts.append("Due: \(task.dueDateTimeString)")
            }
        }
        return parts.joined(separator: " · ")
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(red: 0.90, green: 0.94, blue: 1.0)
        }
        return QuadrantColors.background(for: quadrant)
    }

    private var borderColor: Color {
        if isSelected {
            return .blue
        }
        return QuadrantColors.border(for: quadrant)
    }

    private var borderWidth: CGFloat {
        if isSelected {
            return 3
        }
        return task.isOverdue ? 2 : 1
    }

    private func formatCountdown(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%d days, %02d:%02d:%02d", days, hours, minutes, seconds)
    }
}

// MARK: - Quadrant color palette (shared across views)

enum QuadrantColors {
    // Q1: crimson red, Q2: forest green, Q3: orange, Q4: gray
    static func border(for quadrant: Quadrant) -> Color {
        switch quadrant {
        case .q1: return Color(red: 220.0/255.0, green: 20.0/255.0, blue: 60.0/255.0)
        case .q2: return Color(red: 34.0/255.0, green: 139.0/255.0, blue: 34.0/255.0)
        case .q3: return Color(red: 255.0/255.0, green: 140.0/255.0, blue: 0.0/255.0)
        case .q4: return Color.gray
        }
    }

    static func background(for quadrant: Quadrant) -> Color {
        border(for: quadrant).opacity(0.12)
    }

    static func nsBorder(for quadrant: Quadrant) -> NSColor {
        switch quadrant {
        case .q1: return NSColor(red: 220.0/255.0, green: 20.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        case .q2: return NSColor(red: 34.0/255.0, green: 139.0/255.0, blue: 34.0/255.0, alpha: 1.0)
        case .q3: return NSColor(red: 255.0/255.0, green: 140.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        case .q4: return NSColor.gray
        }
    }
}
