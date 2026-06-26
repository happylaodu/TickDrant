//
//  SettingsManager.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import SwiftUI
import ServiceManagement
import UserNotifications

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    @Published var displayLocation: DisplayLocation {
        didSet {
            UserDefaults.standard.set(displayLocation.rawValue, forKey: "displayLocation")
        }
    }

    private init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")

        let locationRaw = UserDefaults.standard.string(forKey: "displayLocation") ?? "both"
        self.displayLocation = DisplayLocation(rawValue: locationRaw) ?? .both
    }

    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
}

enum DisplayLocation: String, CaseIterable {
    case dockOnly = "dock"
    case menuBarOnly = "menubar"
    case both = "both"

    var displayName: String {
        switch self {
        case .dockOnly: return "Dock Only"
        case .menuBarOnly: return "Menu Bar Only"
        case .both: return "Both"
        }
    }
}
