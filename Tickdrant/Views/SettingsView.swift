//
//  SettingsView.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
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
                        Text("App Version:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Data Location:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("~/Library/Application Support/Tickdrant")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                } header: {
                    Text("About")
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

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
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
}

#Preview {
    SettingsView()
}
