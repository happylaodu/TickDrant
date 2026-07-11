//
//  QuadrantView.swift
//  Tickdrant
//
//  Eisenhower Matrix visualization with tasks plotted by importance × urgency.
//

import SwiftUI
import AppKit

struct QuadrantView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Binding var selectedTask: DueTask?
    let onEdit: (DueTask) -> Void
    let onComplete: (DueTask) -> Void
    let onCompleteAndNext: (DueTask) -> Void
    let onDelete: (DueTask) -> Void

    @State private var hoveredTaskId: UUID?
    // Refreshes once a minute so the layout responds to time passing.
    @State private var refreshTick: Date = Date()

    private static let margin: CGFloat = 10
    private static let topMargin: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            content(size: geo.size)
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { now in
            refreshTick = now
        }
    }

    @ViewBuilder
    private func content(size: CGSize) -> some View {
        let layouts = computeLayouts(in: size)
        ZStack(alignment: .topLeading) {
            backgroundCanvas
            taskBoxesLayer(layouts: layouts)
            tooltipLayer(layouts: layouts, viewSize: size)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var backgroundCanvas: some View {
        Canvas { ctx, sz in
            drawQuadrantBackgrounds(ctx, size: sz)
            drawAxes(ctx, size: sz)
            drawWatermarks(ctx, size: sz)
        }
    }

    @ViewBuilder
    private func taskBoxesLayer(layouts: [TaskLayout]) -> some View {
        ForEach(layouts) { layout in
            taskBox(for: layout)
        }
    }

    @ViewBuilder
    private func taskBox(for layout: TaskLayout) -> some View {
        TaskBoxView(
            task: layout.task,
            isHovered: hoveredTaskId == layout.task.id,
            onEdit: { onEdit(layout.task) },
            onComplete: { onComplete(layout.task) },
            onCompleteAndNext: { onCompleteAndNext(layout.task) },
            onDelete: { onDelete(layout.task) }
        )
        .frame(width: layout.rect.width, height: layout.rect.height)
        // .onHover must be attached BEFORE .position — .position expands the
        // view's hit area to fill the parent, which would make hover fire
        // anywhere in the quadrant area.
        .onHover { hovering in
            if hovering {
                hoveredTaskId = layout.task.id
            } else if hoveredTaskId == layout.task.id {
                hoveredTaskId = nil
            }
        }
        .position(x: layout.rect.midX, y: layout.rect.midY)
    }

    @ViewBuilder
    private func tooltipLayer(layouts: [TaskLayout], viewSize: CGSize) -> some View {
        if let id = hoveredTaskId,
           let layout = layouts.first(where: { $0.task.id == id }) {
            tooltipView(for: layout.task, taskBounds: layout.rect, viewSize: viewSize)
        }
    }

    // MARK: - Layout

    private struct TaskLayout: Identifiable {
        let task: DueTask
        let rect: CGRect
        var id: UUID { task.id }
    }

    private func computeLayouts(in size: CGSize) -> [TaskLayout] {
        guard size.width > 50, size.height > 50 else { return [] }

        let tasks = taskManager.activeTasks
        let now = refreshTick
        let margin = Self.margin
        let topMargin = Self.topMargin
        let plotWidth = size.width - 2 * margin
        let plotHeight = size.height - topMargin - margin

        // Find max non-urgent days for adaptive scaling
        var maxNonUrgentDays = QuadrantConfig.urgencyThresholdDays
        for task in tasks {
            if let due = task.dueDateTime {
                let days = due.timeIntervalSince(now) / 86400.0
                if days >= QuadrantConfig.urgencyThresholdDays && days > maxNonUrgentDays {
                    maxNonUrgentDays = days
                }
            }
        }

        var placedBoxes: [CGRect] = []
        var layouts: [TaskLayout] = []

        let labelFont = NSFont.boldSystemFont(ofSize: 12)

        for task in tasks {
            let urgencyPercent = calculateUrgencyPercent(task: task, now: now, maxNonUrgentDays: maxNonUrgentDays)
            let importancePercent = Double(task.effectiveImportance - 1) / 9.0

            let x = margin + CGFloat(urgencyPercent) * plotWidth
            let y = topMargin + plotHeight - CGFloat(importancePercent) * plotHeight

            // Measure text width
            let textSize = (task.name as NSString).size(withAttributes: [.font: labelFont])
            let overdueSymbolWidth: CGFloat = task.isOverdue ? 20 : 0
            let recurringSymbolWidth: CGFloat = task.isRecurring ? 16 : 0
            let boxWidth = textSize.width + overdueSymbolWidth + recurringSymbolWidth + 20
            let boxHeight: CGFloat = 30

            var boxX = x - boxWidth / 2
            var boxY = y - boxHeight / 2

            boxX = max(margin, min(boxX, margin + plotWidth - boxWidth))
            boxY = max(topMargin, min(boxY, topMargin + plotHeight - boxHeight))

            var rect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
            rect = findNonOverlappingPosition(rect: rect,
                                              placed: placedBoxes,
                                              minX: margin,
                                              minY: topMargin,
                                              maxX: margin + plotWidth,
                                              maxY: topMargin + plotHeight)

            placedBoxes.append(rect)
            layouts.append(TaskLayout(task: task, rect: rect))
        }

        return layouts
    }

    private func calculateUrgencyPercent(task: DueTask, now: Date, maxNonUrgentDays: Double) -> Double {
        guard let due = task.dueDateTime else { return 0.0 }
        let days = due.timeIntervalSince(now) / 86400.0
        let threshold = QuadrantConfig.urgencyThresholdDays

        if days <= 0 { return 1.0 }

        if days < threshold {
            return 0.5 + 0.5 * (threshold - days) / threshold
        }

        if maxNonUrgentDays <= threshold { return 0.25 }
        let logRatio = log(days / threshold) / log(maxNonUrgentDays / threshold)
        return 0.05 + 0.45 * (1.0 - logRatio)
    }

    private func findNonOverlappingPosition(rect: CGRect,
                                            placed: [CGRect],
                                            minX: CGFloat,
                                            minY: CGFloat,
                                            maxX: CGFloat,
                                            maxY: CGFloat) -> CGRect {
        if !hasCollision(rect, placed: placed) { return rect }

        let originalX = rect.origin.x
        let originalY = rect.origin.y
        let step: CGFloat = 5
        let maxAttempts = 100

        for attempt in 1...maxAttempts {
            let offset = step * CGFloat(attempt)
            let candidates: [(CGFloat, CGFloat)] = [
                (offset, 0), (offset, offset), (0, offset), (-offset, offset),
                (-offset, 0), (-offset, -offset), (0, -offset), (offset, -offset)
            ]
            for (dx, dy) in candidates {
                let nx = max(minX, min(originalX + dx, maxX - rect.width))
                let ny = max(minY, min(originalY + dy, maxY - rect.height))
                let newRect = CGRect(x: nx, y: ny, width: rect.width, height: rect.height)
                if !hasCollision(newRect, placed: placed) {
                    return newRect
                }
            }
        }
        return rect
    }

    private func hasCollision(_ rect: CGRect, placed: [CGRect]) -> Bool {
        for p in placed where rect.intersects(p) { return true }
        return false
    }

    // MARK: - Drawing helpers

    private func drawQuadrantBackgrounds(_ ctx: GraphicsContext, size: CGSize) {
        let midX = size.width / 2
        let midY = (Self.topMargin + (size.height - Self.topMargin - Self.margin) / 2)

        // Q2 top-left (green)
        ctx.fill(Path(CGRect(x: 0, y: 0, width: midX, height: midY)),
                 with: .color(Color(red: 34/255, green: 139/255, blue: 34/255).opacity(0.12)))
        // Q1 top-right (red)
        ctx.fill(Path(CGRect(x: midX, y: 0, width: size.width - midX, height: midY)),
                 with: .color(Color(red: 220/255, green: 20/255, blue: 60/255).opacity(0.12)))
        // Q4 bottom-left (gray)
        ctx.fill(Path(CGRect(x: 0, y: midY, width: midX, height: size.height - midY)),
                 with: .color(Color.gray.opacity(0.08)))
        // Q3 bottom-right (orange)
        ctx.fill(Path(CGRect(x: midX, y: midY, width: size.width - midX, height: size.height - midY)),
                 with: .color(Color(red: 255/255, green: 140/255, blue: 0/255).opacity(0.12)))
    }

    private func drawAxes(_ ctx: GraphicsContext, size: CGSize) {
        let margin = Self.margin
        let topMargin = Self.topMargin
        let plotWidth = size.width - 2 * margin
        let plotHeight = size.height - topMargin - margin
        let midX = margin + plotWidth / 2
        let midY = topMargin + plotHeight / 2
        let arrow: CGFloat = 8

        let axisColor = Color.black.opacity(0.7)

        // X axis (Urgency)
        var xPath = Path()
        xPath.move(to: CGPoint(x: margin, y: midY))
        xPath.addLine(to: CGPoint(x: margin + plotWidth, y: midY))
        ctx.stroke(xPath, with: .color(axisColor), lineWidth: 2)

        // Right arrow
        var xArrow = Path()
        xArrow.move(to: CGPoint(x: margin + plotWidth, y: midY))
        xArrow.addLine(to: CGPoint(x: margin + plotWidth - arrow, y: midY - arrow/2))
        xArrow.addLine(to: CGPoint(x: margin + plotWidth - arrow, y: midY + arrow/2))
        xArrow.closeSubpath()
        ctx.fill(xArrow, with: .color(axisColor))

        // Y axis (Importance)
        var yPath = Path()
        yPath.move(to: CGPoint(x: midX, y: topMargin + plotHeight))
        yPath.addLine(to: CGPoint(x: midX, y: topMargin))
        ctx.stroke(yPath, with: .color(axisColor), lineWidth: 2)

        // Up arrow
        var yArrow = Path()
        yArrow.move(to: CGPoint(x: midX, y: topMargin))
        yArrow.addLine(to: CGPoint(x: midX - arrow/2, y: topMargin + arrow))
        yArrow.addLine(to: CGPoint(x: midX + arrow/2, y: topMargin + arrow))
        yArrow.closeSubpath()
        ctx.fill(yArrow, with: .color(axisColor))

        // Axis labels
        let labelFont = Font.system(size: 11, weight: .bold)
        ctx.draw(Text("Urgency →").font(labelFont).foregroundColor(axisColor),
                 at: CGPoint(x: margin + plotWidth - 35, y: midY + 12),
                 anchor: .center)
        ctx.draw(Text("Importance").font(labelFont).foregroundColor(axisColor),
                 at: CGPoint(x: midX, y: 10),
                 anchor: .center)
    }

    private func drawWatermarks(_ ctx: GraphicsContext, size: CGSize) {
        let margin = Self.margin
        let topMargin = Self.topMargin
        let plotWidth = size.width - 2 * margin
        let plotHeight = size.height - topMargin - margin
        let midX = margin + plotWidth / 2
        let midY = topMargin + plotHeight / 2
        let q2cx = midX / 2
        let q1cx = midX + (size.width - midX) / 2
        let topCY = topMargin + (midY - topMargin) / 2
        let botCY = midY + (size.height - midY) / 2

        let watermarkFont = Font.system(size: 32, weight: .bold)

        ctx.draw(Text("Focus Here").font(watermarkFont).foregroundColor(Color(red: 34/255, green: 139/255, blue: 34/255).opacity(0.25)),
                 at: CGPoint(x: q2cx, y: topCY), anchor: .center)

        ctx.draw(Text("Handle Now").font(watermarkFont).foregroundColor(Color(red: 220/255, green: 20/255, blue: 60/255).opacity(0.25)),
                 at: CGPoint(x: q1cx, y: topCY - 18), anchor: .center)
        ctx.draw(Text("Minimize Occurrence").font(watermarkFont).foregroundColor(Color(red: 220/255, green: 20/255, blue: 60/255).opacity(0.25)),
                 at: CGPoint(x: q1cx, y: topCY + 18), anchor: .center)

        ctx.draw(Text("Avoid").font(watermarkFont).foregroundColor(Color.gray.opacity(0.25)),
                 at: CGPoint(x: q2cx, y: botCY), anchor: .center)

        ctx.draw(Text("Decline or Delegate").font(watermarkFont).foregroundColor(Color(red: 255/255, green: 140/255, blue: 0/255).opacity(0.25)),
                 at: CGPoint(x: q1cx, y: botCY), anchor: .center)
    }

    // MARK: - Hover tooltip

    private func tooltipView(for task: DueTask, taskBounds: CGRect, viewSize: CGSize) -> some View {
        let lines = tooltipLines(for: task)
        let layout = computeTooltipLayout(lines: lines, taskBounds: taskBounds, viewSize: viewSize)

        return VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line.text)
                    .font(.system(size: 11, weight: line.bold ? .bold : .regular))
                    .foregroundColor(line.color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 1.0, green: 1.0, blue: 220.0/255.0))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
        )
        .frame(width: layout.size.width, height: layout.size.height)
        .position(x: layout.origin.x + layout.size.width / 2,
                  y: layout.origin.y + layout.size.height / 2)
        .allowsHitTesting(false)
    }

    private func computeTooltipLayout(lines: [TooltipLine],
                                      taskBounds: CGRect,
                                      viewSize: CGSize) -> (origin: CGPoint, size: CGSize) {
        let font = NSFont.systemFont(ofSize: 11)
        let widest = lines.map { ($0.text as NSString).size(withAttributes: [.font: font]).width }.max() ?? 100
        let width = widest + 20
        let height = CGFloat(lines.count) * 16 + 12

        let gap: CGFloat = 8
        var tipY = taskBounds.minY - height - gap
        if tipY < 5 { tipY = taskBounds.maxY + gap }

        let centerX = taskBounds.midX
        var tipX: CGFloat
        if centerX < viewSize.width / 3 {
            tipX = taskBounds.minX
        } else if centerX > viewSize.width * 2 / 3 {
            tipX = taskBounds.maxX - width
        } else {
            tipX = centerX - width / 2
        }
        tipX = max(5, min(tipX, viewSize.width - width - 5))
        tipY = max(5, min(tipY, viewSize.height - height - 5))

        return (CGPoint(x: tipX, y: tipY), CGSize(width: width, height: height))
    }

    private struct TooltipLine {
        let text: String
        let bold: Bool
        let color: Color
    }

    private func tooltipLines(for task: DueTask) -> [TooltipLine] {
        var lines: [TooltipLine] = []
        lines.append(.init(text: task.name, bold: true, color: .black))
        lines.append(.init(text: "Importance: \(task.effectiveImportance)", bold: false, color: .black))

        if let due = task.dueDateTime {
            let interval = due.timeIntervalSince(refreshTick)
            if interval < 0 {
                lines.append(.init(text: "Status: OVERDUE", bold: true,
                                   color: Color(red: 220/255, green: 20/255, blue: 60/255)))
            } else {
                let days = Int(interval / 86400)
                let hours = (Int(interval) % 86400) / 3600
                let minutes = (Int(interval) % 3600) / 60
                if days > 0 {
                    lines.append(.init(text: "Due in: \(days) days, \(hours) hours", bold: false, color: .black))
                } else if hours > 0 {
                    lines.append(.init(text: "Due in: \(hours) hours, \(minutes) min", bold: false, color: .black))
                } else {
                    lines.append(.init(text: "Due in: \(minutes) minutes", bold: false, color: .black))
                }
            }
            lines.append(.init(text: "Due: \(task.dueDateTimeString)", bold: false, color: .black))
        } else {
            lines.append(.init(text: "No deadline", bold: false, color: .black))
        }

        if task.isRecurring {
            let unitName = task.recurrenceUnit.displayName(value: task.recurrenceValue)
            lines.append(.init(text: "Recurring: Every \(task.recurrenceValue) \(unitName)", bold: false, color: .black))
        }
        return lines
    }
}

// MARK: - Task Box (inside Quadrant view)

private struct TaskBoxView: View {
    let task: DueTask
    let isHovered: Bool
    let onEdit: () -> Void
    let onComplete: () -> Void
    let onCompleteAndNext: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 4) {
            if task.isOverdue {
                Text("▲")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 220/255, green: 20/255, blue: 60/255))
            }
            if task.isRecurring {
                Text("🔄")
                    .font(.system(size: 10))
            }
            Text(task.name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(QuadrantColors.border(for: task.quadrant()).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(task.isOverdue
                        ? Color(red: 220/255, green: 20/255, blue: 60/255)
                        : QuadrantColors.border(for: task.quadrant()),
                        lineWidth: task.isOverdue ? 3 : 1)
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onEdit() }
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
                        .foregroundColor(.green)
                }
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
}
