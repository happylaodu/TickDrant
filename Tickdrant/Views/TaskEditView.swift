//
//  TaskEditView.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import SwiftUI

struct TaskEditView: View {
    @Environment(\.dismiss) var dismiss

    let task: DueTask?
    let onSave: (DueTask) -> Void

    @State private var taskName: String
    @State private var importance: Int
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var isRecurring: Bool
    @State private var recurrenceValue: Int
    @State private var recurrenceUnit: DueTask.RecurrenceUnit
    @State private var showValidationError = false
    @State private var validationMessage = ""

    init(task: DueTask?, onSave: @escaping (DueTask) -> Void) {
        self.task = task
        self.onSave = onSave

        _taskName = State(initialValue: task?.name ?? "")
        _importance = State(initialValue: task?.effectiveImportance ?? 3)
        _hasDueDate = State(initialValue: task?.dueDateTime != nil)
        _dueDate = State(initialValue: task?.dueDateTime ?? Date().addingTimeInterval(86400))
        _isRecurring = State(initialValue: task?.isRecurring ?? false)
        _recurrenceValue = State(initialValue: task?.recurrenceValue ?? 1)
        _recurrenceUnit = State(initialValue: task?.recurrenceUnit ?? .days)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(task == nil ? "Add New Task" : "Edit Task")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                // Task name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Task Name")
                        .font(.headline)
                    TextField("Enter task name", text: $taskName)
                        .textFieldStyle(.roundedBorder)
                }

                // Importance
                HStack {
                    Text("Importance:")
                        .font(.headline)
                    Picker("", selection: $importance) {
                        ForEach(1...10, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)
                    Text("(1 = lowest, 10 = highest)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                // Due date checkbox + picker
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Due:", isOn: $hasDueDate)
                        .font(.headline)
                        .onChange(of: hasDueDate) { newValue in
                            if !newValue {
                                isRecurring = false
                            }
                        }

                    if hasDueDate {
                        DatePicker("", selection: $dueDate)
                            .datePickerStyle(.stepperField)
                            .labelsHidden()
                    }
                }

                // Recurrence
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Repeat task every:", isOn: $isRecurring)
                        .font(.headline)
                        .disabled(!hasDueDate)

                    if isRecurring && hasDueDate {
                        HStack {
                            TextField("", value: $recurrenceValue, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)

                            Picker("", selection: $recurrenceUnit) {
                                ForEach(DueTask.RecurrenceUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                        }
                    }
                }
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button(task == nil ? "Add" : "Save") {
                    saveTask()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 440)
        .alert("Validation Error", isPresented: $showValidationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
    }

    private func saveTask() {
        let trimmedName = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Task name cannot be empty."
            showValidationError = true
            return
        }

        var finalDueDate: Date? = nil
        if hasDueDate {
            // Only enforce "future" for new tasks; allow editing past dates to preserve overdue state
            if task == nil && dueDate <= Date() {
                validationMessage = "Due date must be in the future."
                showValidationError = true
                return
            }
            finalDueDate = dueDate
        }

        if isRecurring {
            guard finalDueDate != nil else {
                validationMessage = "Recurring tasks must have a due date."
                showValidationError = true
                return
            }
            guard recurrenceValue >= 1 && recurrenceValue <= 999 else {
                validationMessage = "Recurrence value must be between 1 and 999."
                showValidationError = true
                return
            }
        }

        let newTask = DueTask(
            id: task?.id ?? UUID(),
            name: trimmedName,
            dueDateTime: finalDueDate,
            importance: importance,
            isRecurring: isRecurring && finalDueDate != nil,
            recurrenceValue: recurrenceValue,
            recurrenceUnit: recurrenceUnit,
            completed: task?.completed ?? false,
            completedDateTime: task?.completedDateTime
        )

        onSave(newTask)
        dismiss()
    }
}
