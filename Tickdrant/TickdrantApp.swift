//
//  TickdrantApp.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import SwiftUI
import os

@main
struct TickdrantApp: App {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var menuBarManager = MenuBarManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskManager)
                .environmentObject(menuBarManager)
                .onAppear {
                    updateActivationPolicy()
                    menuBarManager.setup(taskManager: taskManager)
                    appDelegate.menuBarManager = menuBarManager
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView(menuBarManager: menuBarManager)
                .environmentObject(taskManager)
        }
    }

    private func updateActivationPolicy() {
        let displayLocation = SettingsManager.shared.displayLocation

        switch displayLocation {
        case .dockOnly:
            NSApp.setActivationPolicy(.regular)
        case .menuBarOnly:
            NSApp.setActivationPolicy(.accessory)
        case .both:
            NSApp.setActivationPolicy(.regular)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private static let logger = Logger(subsystem: "com.brightjune.Tickdrant", category: "AppDelegate")
    var menuBarManager: MenuBarManager?
    private var mainWindow: NSWindow?
    private var windowSetupTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindowNotifications()

        // Use a timer to find and retain the main window after it's created
        windowSetupTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            self?.findAndRetainMainWindow()
        }
    }

    @discardableResult
    private func findAndRetainMainWindow() -> Bool {
        // If we already have the window, just update its delegate
        if let window = mainWindow {
            if window.delegate == nil {
                window.delegate = self
                Self.logger.debug("Updated delegate for retained main window")
            }
            return true
        }

        // Find the main window
        for window in NSApp.windows {
            let windowClass = String(describing: type(of: window))
            let isAppKitWindow = windowClass.contains("AppKitWindow") &&
                                 !windowClass.contains("NSStatusBarWindow") &&
                                 !windowClass.contains("NSPopupMenuWindow")

            if isAppKitWindow {
                let hasSettings = window.contentView?.subviews.contains(where: { view in
                    String(describing: type(of: view)).contains("Settings")
                }) ?? false

                if !hasSettings {
                    mainWindow = window
                    window.delegate = self
                    Self.logger.debug("Found and retained main window: \(window)")
                    windowSetupTimer?.invalidate()
                    windowSetupTimer = nil
                    return true
                }
            }
        }

        return false
    }

    // Intercept window close to hide instead
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Check if this is the main window
        if sender === mainWindow {
            Self.logger.debug("Intercepting main window close, hiding instead")
            sender.orderOut(nil)
            return false
        }

        // Allow other windows (like Settings) to close normally
        Self.logger.debug("Allowing window to close: \(sender)")
        return true
    }

    private func setupWindowNotifications() {
        // Listen for show main window notification
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowMainWindow"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Self.logger.debug("ShowMainWindow notification received")
            NSApp.activate(ignoringOtherApps: true)

            if let window = self.mainWindow {
                Self.logger.debug("Showing retained main window: \(window)")
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
            } else {
                Self.logger.debug("Main window not yet initialized, trying to find it")
                self.findAndRetainMainWindow()

                if let window = self.mainWindow {
                    Self.logger.debug("Found and showing main window: \(window)")
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                } else {
                    Self.logger.debug("No main window found")
                }
            }
        }

        // Listen for show settings notification
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowSettings"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Self.logger.debug("AppDelegate received ShowSettings notification")

            // Temporarily change activation policy if needed
            let displayLocation = SettingsManager.shared.displayLocation
            if displayLocation == .menuBarOnly {
                Self.logger.debug("Changing activation policy to .regular")
                NSApp.setActivationPolicy(.regular)
            }

            NSApp.activate(ignoringOtherApps: true)

            // Ensure main window exists and is visible
            if self.mainWindow == nil {
                Self.logger.debug("Main window not initialized, finding it")
                self.findAndRetainMainWindow()
            }

            if let window = self.mainWindow {
                Self.logger.debug("Showing main window for settings: \(window)")
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()

                // Trigger settings sheet after a short delay to ensure window is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    Self.logger.debug("Posting TriggerSettingsSheet notification")
                    NotificationCenter.default.post(name: NSNotification.Name("TriggerSettingsSheet"), object: nil)
                }
            } else {
                Self.logger.error("Failed to find main window for settings")
            }
        }
    }
}
