//
//  MenuBarManager.swift
//  Tickdrant
//
//  Created on 2026-03-08.
//

import SwiftUI
import AppKit
import Combine
import os

private let logger = Logger(subsystem: "com.brightjune.Tickdrant", category: "MenuBarManager")

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var taskManager: TaskManager?
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Tasks are "urgent" (badge-worthy) if they are overdue or due within this window.
    private static let urgentWindow: TimeInterval = 24 * 3600

    func setup(taskManager: TaskManager) {
        self.taskManager = taskManager

        // Refresh the badge whenever the task list changes (add/edit/complete/delete).
        taskManager.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateBadge()
            }
            .store(in: &cancellables)

        updateMenuBarVisibility()
    }

    func updateMenuBarVisibility() {
        let displayLocation = SettingsManager.shared.displayLocation

        switch displayLocation {
        case .menuBarOnly, .both:
            showMenuBar()
        case .dockOnly:
            hideMenuBar()
        }
    }

    private func showMenuBar() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock.badge.checkmark", accessibilityDescription: "Tickdrant")
            button.imagePosition = .imageLeading
        }

        updateMenu()
        updateBadge()

        // Refresh menu + badge every minute so countdowns and the urgent count stay current
        // as time passes (e.g., a task crosses the 24h threshold).
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateMenu()
            self?.updateBadge()
        }
    }

    private func hideMenuBar() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    // MARK: - Urgent-task badge

    private func updateBadge() {
        guard let button = statusItem?.button else { return }
        let count = urgentTaskCount()
        if count > 0 {
            let displayText = count > 99 ? "99+" : "\(count)"
            button.attributedTitle = NSAttributedString(string: " \(displayText)", attributes: [
                .foregroundColor: NSColor.systemRed,
                .font: NSFont.systemFont(ofSize: 11, weight: .bold)
            ])
        } else {
            button.attributedTitle = NSAttributedString(string: "")
        }
    }

    private func urgentTaskCount() -> Int {
        guard let taskManager = taskManager else { return 0 }
        let now = Date()
        return taskManager.activeTasks.filter { task in
            guard let due = task.dueDateTime else { return false }
            return due.timeIntervalSince(now) <= Self.urgentWindow
        }.count
    }

    private func updateMenu() {
        guard let taskManager = taskManager else { return }

        let menu = NSMenu()
        menu.delegate = self

        // Show next upcoming task (highest priority quadrant, with a due date)
        let nextTask = taskManager.quadrantSortedActiveTasks.first(where: { $0.dueDateTime != nil })
        if let task = nextTask, let due = task.dueDateTime {
            let timeString = formatCountdown(to: due)
            let item = NSMenuItem(title: "\(task.name): \(timeString)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(NSMenuItem.separator())
        } else {
            let noTaskItem = NSMenuItem(title: "No upcoming tasks", action: nil, keyEquivalent: "")
            noTaskItem.isEnabled = false
            menu.addItem(noTaskItem)
            menu.addItem(NSMenuItem.separator())
        }

        // Show main window
        let showWindowItem = NSMenuItem(title: "Show Main Window", action: #selector(showMainWindow), keyEquivalent: "")
        showWindowItem.target = self
        menu.addItem(showWindowItem)

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func showMainWindow() {
        logger.debug("Show Main Window clicked")
        NotificationCenter.default.post(name: NSNotification.Name("ShowMainWindow"), object: nil)
    }

    @objc private func openSettings() {
        logger.debug("Settings clicked")
        NotificationCenter.default.post(name: NSNotification.Name("ShowSettings"), object: nil)
    }

    private func formatCountdown(to date: Date) -> String {
        let interval = date.timeIntervalSinceNow

        if interval < 0 {
            return "OVERDUE"
        }

        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

extension MenuBarManager: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        logger.debug("Menu opened")
    }
}
