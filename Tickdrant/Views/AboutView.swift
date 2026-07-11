//
//  AboutView.swift
//  Tickdrant
//
//  Standard macOS About window, styled to match the sibling app
//  Pomodoro Timer Lite.
//

import SwiftUI
import AppKit

struct AboutView: View {
    private static let githubURL = URL(string: "https://github.com/happylaodu/TickDrant")!
    private static let pomodoroURL = URL(string: "https://apps.apple.com/app/pomodoro-timer-lite/id6748662476")!

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 128, height: 128)
                }
                Text("Tickdrant")
                    .font(.system(size: 28, weight: .bold))
                Text("Version \(appVersion)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()

            Text("A native macOS task manager combining an Eisenhower priority matrix with live countdown timers. See what's urgent, what's important, and what deserves your attention right now.")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)
                .padding(.vertical, 20)

            Divider()

            VStack(spacing: 10) {
                infoRow("Developer:", "Zhifeng Du")
                infoRow("Copyright:", "© 2026 Zhifeng Du")
                infoRow("System Requirements:", "macOS 13+")
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 18)

            Divider()

            VStack(spacing: 10) {
                Link(destination: Self.githubURL) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("Open Source on GitHub")
                    }
                }
            }
            .padding(.vertical, 18)

            Divider()

            Text("Licensed under MIT License")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.vertical, 12)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Also from Zhifeng Du")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                HStack(spacing: 10) {
                    Image("PomodoroIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pomodoro Timer Lite")
                            .fontWeight(.medium)
                        Text("Focus timer companion app")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Link("View on App Store", destination: Self.pomodoroURL)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 18)
        }
        .frame(width: 400)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
        }
        .font(.system(size: 13))
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (Build \(build))"
    }
}

#Preview {
    AboutView()
}
