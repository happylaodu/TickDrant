//
//  SettingsView.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) var dismiss

    var menuBarManager: MenuBarManager? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    handleDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Settings Content
            Form {
                Section {
                    // Launch at Login
                    Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                        .help("Automatically start the app when you log in to your Mac")

                    // Notifications
                    HStack {
                        Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                            .help("Allow the app to send notifications for upcoming tasks")

                        if !settings.notificationsEnabled {
                            Button("Grant Permission") {
                                settings.requestNotificationPermission()
                            }
                            .buttonStyle(.link)
                        }
                    }

                    // Display Location
                    Picker("Display Location:", selection: $settings.displayLocation) {
                        ForEach(DisplayLocation.allCases, id: \.self) { location in
                            Text(location.displayName).tag(location)
                        }
                    }
                    .help("Choose where the app appears: Dock, Menu Bar, or both")
                    .onChange(of: settings.displayLocation) { newValue in
                        updateDisplayLocation(newValue)
                    }
                } header: {
                    Text("General")
                        .font(.headline)
                }

                Section {
                    HStack {
                        Text("Backup or transfer your tasks as a JSON file.")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                        Spacer()
                    }
                    HStack {
                        Button("Export Tasks…") { exportTasks() }
                            .help("Save all current tasks to a JSON file")
                        Button("Import Tasks…") { importTasks() }
                            .help("Load tasks from a previously exported JSON file")
                        Spacer()
                    }
                } header: {
                    Text("Data")
                        .font(.headline)
                }

            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 500, height: 400)
        .onDisappear {
            restoreActivationPolicyIfNeeded()
        }
    }

    private func handleDismiss() {
        dismiss()
        restoreActivationPolicyIfNeeded()
    }

    private func restoreActivationPolicyIfNeeded() {
        // Restore activation policy when settings closes
        let displayLocation = SettingsManager.shared.displayLocation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch displayLocation {
            case .menuBarOnly:
                NSApp.setActivationPolicy(.accessory)
            case .dockOnly, .both:
                NSApp.setActivationPolicy(.regular)
            }
        }
    }

    private func updateDisplayLocation(_ location: DisplayLocation) {
        // Update activation policy
        switch location {
        case .dockOnly:
            NSApp.setActivationPolicy(.regular)
        case .menuBarOnly:
            NSApp.setActivationPolicy(.accessory)
        case .both:
            NSApp.setActivationPolicy(.regular)
        }

        // Update menu bar visibility
        menuBarManager?.updateMenuBarVisibility()
    }

    // MARK: - Export / Import

    private func exportTasks() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = defaultExportFilename()
        panel.title = "Export Tasks"
        panel.message = "Save your tasks to a JSON file for backup or transfer."
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try taskManager.exportTasks(to: url)
                showAlert(title: "Export Successful",
                          message: "Saved \(taskManager.tasks.count) task(s) to \(url.lastPathComponent).",
                          style: .informational)
            } catch {
                showAlert(title: "Export Failed",
                          message: error.localizedDescription,
                          style: .warning)
            }
        }
    }

    private func importTasks() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Import Tasks"
        panel.message = "Select a JSON file exported from Tickdrant."

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            DispatchQueue.main.async {
                askImportMode(for: url)
            }
        }
    }

    private func askImportMode(for url: URL) {
        let alert = NSAlert()
        alert.messageText = "Import Tasks"
        alert.informativeText = "How do you want to import tasks from “\(url.lastPathComponent)”?\n\n• Merge: add new tasks, skip duplicates.\n• Replace All: discard existing tasks and use only the imported ones."
        alert.addButton(withTitle: "Merge")
        alert.addButton(withTitle: "Replace All")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational

        let response = alert.runModal()
        let mode: TaskManager.ImportMode
        switch response {
        case .alertFirstButtonReturn:  mode = .merge
        case .alertSecondButtonReturn: mode = .replace
        default: return
        }

        do {
            let result = try taskManager.importTasks(from: url, mode: mode)
            let summary: String
            switch mode {
            case .merge:
                summary = "Added \(result.added) new task(s); skipped \(result.skipped) duplicate(s)."
            case .replace:
                summary = "Replaced existing tasks. Imported \(result.added) task(s)."
            }
            showAlert(title: "Import Successful", message: summary, style: .informational)
        } catch {
            showAlert(title: "Import Failed", message: error.localizedDescription, style: .warning)
        }
    }

    private func showAlert(title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func defaultExportFilename() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        return "tickdrant-tasks-\(df.string(from: Date())).json"
    }
}

#Preview {
    SettingsView()
        .environmentObject(TaskManager())
}
