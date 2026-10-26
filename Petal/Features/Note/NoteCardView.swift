import PetalKit
import SwiftUI

public struct NoteCardView: View {
    @Bindable var viewModel: NoteViewModel
    public var audioRecorder: any AudioRecorder
    public var speechTranscriber: any PetalSpeechTranscriber
    public var onResize: ((CGSize) -> Void)?
    public var onClose: (() -> Void)?
    public var onOpenStackList: (() -> Void)?

    @State private var hoveredButton: String?
    @State private var hoveredTaskID: UUID?
    @State private var prevResizeTranslation: CGSize = .zero
    @State private var isResizeHovered: Bool = false
    @State private var isHoveredPeek: Bool = false
    @State private var isPillHovered: Bool = false
    @State private var isPopoverHovered: Bool = false
    @State private var isDateHovered: Bool = false
    @State private var isAddTaskHovered: Bool = false
    @State private var isFolderHovered: Bool = false
    @State private var isStackHovered: Bool = false
    @State private var isPinHovered: Bool = false
    @State private var isCollapseHovered: Bool = false
    @State private var isCloseHovered: Bool = false
    @State private var peekDismissTask: Task<Void, Never>?

    private func updateHoverState(pill: Bool? = nil, popover: Bool? = nil) {
        if let pill = pill { isPillHovered = pill }
        if let popover = popover { isPopoverHovered = popover }

        peekDismissTask?.cancel()
        if isPillHovered || isPopoverHovered {
            isHoveredPeek = true
        } else {
            peekDismissTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if !Task.isCancelled {
                    isHoveredPeek = false
                }
            }
        }
    }

    public init(
        viewModel: NoteViewModel,
        audioRecorder: any AudioRecorder,
        speechTranscriber: any PetalSpeechTranscriber,
        onResize: ((CGSize) -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onOpenStackList: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.audioRecorder = audioRecorder
        self.speechTranscriber = speechTranscriber
        self.onResize = onResize
        self.onClose = onClose
        self.onOpenStackList = onOpenStackList
    }

    public var body: some View {
        Group {
            if viewModel.note.isCollapsed {
                collapsedView
            } else {
                expandedCardView
            }
        }
        .environment(\.colorScheme, viewModel.note.color.requiresDarkText ? .light : .dark)
        .preferredColorScheme(viewModel.note.color.requiresDarkText ? .light : .dark)
    }

    // MARK: - Collapsed View (Desktop Pill)

    @ViewBuilder
    private var collapsedView: some View {
        if viewModel.note.collapseStyle == .mini {
            collapsedMiniView
        } else {
            collapsedPillView
        }
    }

    private var hoverTooltipSummary: String {
        var lines: [String] = []
        let title = viewModel.note.title.trimmingCharacters(in: .whitespaces)
        lines.append(title.isEmpty ? "Untitled Note" : title)

        if !viewModel.note.previewSnippet.isEmpty {
            lines.append(viewModel.note.previewSnippet)
        }

        if !viewModel.note.checklist.isEmpty {
            let done = viewModel.note.checklist.filter(\.isDone).count
            lines.append("Tasks: \(done)/\(viewModel.note.checklist.count) completed")
        }

        if let timer = viewModel.note.timerSession {
            lines.append("Timer: \(timer.formattedRemaining(at: Date()))")
        }

        if let rem = viewModel.note.reminder {
            lines.append("Reminder: \(rem.targetDate.formatted(date: .omitted, time: .shortened))")
        }

        lines.append("Click to expand • Drag to move")
        return lines.joined(separator: "\n")
    }

    private var collapsedPillView: some View {
        let bg = PetalColor.resolve(noteColor: viewModel.note.color, theme: viewModel.currentTheme)
        let textColor = PetalColor.textColor(for: viewModel.note.color, theme: viewModel.currentTheme)
        let isDarkText = viewModel.note.color.requiresDarkText
        let titlePrefix: String = {
            let t = viewModel.note.title.trimmingCharacters(in: .whitespaces)
            if t.isEmpty {
                return "Note"
            }
            if t.count <= 6 {
                return t
            }
            return String(t.prefix(5)) + "…"
        }()

        return HStack(spacing: 5) {
            // Icon: timer, reminder, alarm, or color dot
            if viewModel.note.hasActiveTimer, let timer = viewModel.note.timerSession {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    HStack(spacing: 3) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.blue)
                        Text(timer.formattedRemaining(at: context.date))
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                }
            } else if viewModel.note.hasActiveReminder {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.orange)
            } else if viewModel.note.hasActiveAlarm {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.purple)
            } else {
                Circle()
                    .fill(Color(hex: viewModel.note.color.hex))
                    .frame(width: 7.5, height: 7.5)
                    .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 0.8))
            }

            // Small title prefix
            Text(titlePrefix)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .lineLimit(1)

            Spacer(minLength: 0)

            // Mini chevron indicator
            Image(systemName: "chevron.up")
                .font(.system(size: 7, weight: .heavy))
                .foregroundColor(textColor.opacity(0.45))
        }
        .padding(.horizontal, 7.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Capsule().fill(bg)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(isDarkText ? 0.35 : 0.12), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                WindowDragArea(onDoubleClick: {
                    isHoveredPeek = false
                    viewModel.toggleCollapse()
                })
            }
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(isDarkText ? 0.6 : 0.25), Color.black.opacity(0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            isHoveredPeek = false
            viewModel.toggleCollapse()
        }
        .contextMenu {
            Button("Expand Note") {
                isHoveredPeek = false
                viewModel.toggleCollapse()
            }
            Divider()
            Button("Collapse All Notes (⌃⌥C)") {
                AppState.shared.collapseAllNotes()
            }
            Button("See All Notes (⌃⌥E)") {
                AppState.shared.expandAllNotes()
            }
            Divider()
            Button("All Notes & Stack Manager (⌘L)") {
                isHoveredPeek = false
                onOpenStackList?()
            }
            Divider()
            Button(viewModel.note.isPinned ? "Unpin Note" : "Pin Note") {
                viewModel.togglePin()
            }
            Button("Close Note") {
                isHoveredPeek = false
                onClose?()
            }
        }
        .onHover { isHov in
            updateHoverState(pill: isHov)
        }
        .popover(isPresented: $isHoveredPeek, arrowEdge: .bottom) {
            collapsedHoverInfoCard(textColor: textColor, bg: bg, isDarkText: isDarkText)
                .onHover { isHov in
                    updateHoverState(popover: isHov)
                }
        }
        .help(hoverTooltipSummary)
    }

    private func collapsedHoverInfoCard(textColor: Color, bg: Color, isDarkText: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: viewModel.note.color.hex))
                    .frame(width: 8.5, height: 8.5)
                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 0.8))

                Text(viewModel.note.title.isEmpty ? "Untitled Note" : viewModel.note.title)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .lineLimit(1)

                Spacer()

                // All Notes (Stack Manager) Button
                Button(action: {
                    isHoveredPeek = false
                    onOpenStackList?()
                }) {
                    HStack(spacing: 3.5) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 9.5, weight: .semibold))
                        Text("Stack")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(textColor.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Color.black.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .help("All Notes (Stack Manager - ⌘L)")

                // Expand button
                Button(action: {
                    isHoveredPeek = false
                    viewModel.toggleCollapse()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(textColor.opacity(0.8))
                        .frame(width: 20, height: 20)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .help("Expand note (Double-click)")
            }

            if !viewModel.note.previewSnippet.isEmpty {
                Text(viewModel.note.previewSnippet)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(textColor.opacity(0.8))
                    .lineLimit(3)
            }

            if !viewModel.note.checklist.isEmpty {
                let doneCount = viewModel.note.checklist.filter(\.isDone).count
                HStack(spacing: 4.5) {
                    Image(systemName: "checklist")
                        .font(.system(size: 9.5))
                        .foregroundColor(Color(hex: "#22C55E"))
                    Text("\(doneCount) of \(viewModel.note.checklist.count) tasks done")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(textColor.opacity(0.8))
                }
            }

            // Date badge
            HStack(spacing: 4.5) {
                Image(systemName: "calendar")
                    .font(.system(size: 8.5))
                    .foregroundColor(textColor.opacity(0.65))
                Text(viewModel.note.createdAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(textColor.opacity(0.75))
            }

            if let timer = viewModel.note.timerSession {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    HStack(spacing: 4.5) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 9))
                            .foregroundColor(.blue)
                        Text("Focus: \(timer.formattedRemaining(at: context.date))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                }
            }

            if let rem = viewModel.note.reminder {
                HStack(spacing: 4.5) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text("Reminder: \(rem.targetDate.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
        .frame(width: 230)
        .background(
            ZStack {
                bg.opacity(0.98)
                LinearGradient(
                    colors: [Color.white.opacity(isDarkText ? 0.25 : 0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.8)
        )
        .onTapGesture(count: 2) {
            isHoveredPeek = false
            viewModel.toggleCollapse()
        }
    }

    private var collapsedMiniView: some View {
        let bg = PetalColor.resolve(noteColor: viewModel.note.color, theme: viewModel.currentTheme)
        let textColor = PetalColor.textColor(for: viewModel.note.color, theme: viewModel.currentTheme)
        let isDarkText = viewModel.note.color.requiresDarkText

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color(hex: viewModel.note.color.hex))
                    .frame(width: 7, height: 7)
                Text(viewModel.note.title.isEmpty ? "Untitled" : viewModel.note.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                Spacer()
                Button(action: { viewModel.toggleCollapse() }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(textColor.opacity(0.65))
                        .frame(width: 16, height: 16)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Expand note")
            }

            Text(viewModel.note.previewSnippet.isEmpty ? "No content" : viewModel.note.previewSnippet)
                .font(.system(size: 9.5, design: .rounded))
                .foregroundColor(textColor.opacity(0.75))
                .lineLimit(2)

            Spacer()

            HStack(spacing: 4) {
                if viewModel.note.hasActiveTimer {
                    Image(systemName: "hourglass")
                        .font(.system(size: 8.5))
                        .foregroundColor(.blue)
                }
                if viewModel.note.hasActiveReminder {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 8.5))
                        .foregroundColor(.orange)
                }
                if viewModel.note.hasActiveAlarm {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 8.5))
                        .foregroundColor(.purple)
                }
                if viewModel.note.hasVoiceNote {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 8.5))
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                bg
                LinearGradient(
                    colors: [Color.white.opacity(isDarkText ? 0.25 : 0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                WindowDragArea(onDoubleClick: {
                    viewModel.toggleCollapse()
                })
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1.5)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            viewModel.toggleCollapse()
        }
        .contextMenu {
            Button("Collapse Note") {
                viewModel.toggleCollapse()
            }
            Divider()
            Button("Collapse All Notes (⌃⌥C)") {
                AppState.shared.collapseAllNotes()
            }
            Button("See All Notes (⌃⌥E)") {
                AppState.shared.expandAllNotes()
            }
            Divider()
            Button("All Notes & Stack Manager (⌘L)") {
                onOpenStackList?()
            }
            Divider()
            Button(viewModel.note.isPinned ? "Unpin Note" : "Pin Note") {
                viewModel.togglePin()
            }
            Button("Close Note") {
                onClose?()
            }
        }
    }

    // MARK: - Expanded Card View

    private var expandedCardView: some View {
        let bg = PetalColor.resolve(noteColor: viewModel.note.color, theme: viewModel.currentTheme)
        let textColor = PetalColor.textColor(for: viewModel.note.color, theme: viewModel.currentTheme)
        let secondaryColor = PetalColor.secondaryTextColor(for: viewModel.note.color, theme: viewModel.currentTheme)
        let isDarkText = viewModel.note.color.requiresDarkText

        return VStack(alignment: .leading, spacing: 0) {
            // Top Strip (Clean Drag Bar with Visionary Micro-Buttons)
            topHeaderStrip(textColor: textColor, secondaryColor: secondaryColor, isDarkText: isDarkText)
                .layoutPriority(2)

            // Title Field
            titleEditor(textColor: textColor)
                .padding(.horizontal, Spacing.m)
                .padding(.top, 4)

            // Date Badge (Interactive Calendar Capsule)
            noteDateBadge(secondaryColor: secondaryColor, isDarkText: isDarkText)
                .padding(.horizontal, Spacing.m)
                .padding(.top, 2)
                .padding(.bottom, 2)

            // Body & Checklist
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    bodyEditor(textColor: textColor)

                    if !viewModel.note.checklist.isEmpty {
                        checklistSection(textColor: textColor, isDarkText: isDarkText)
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, 4)
                .padding(.bottom, 6)
            }
            .frame(maxHeight: .infinity)

            // Status Chips (Reminder, Alarm, Timer, Voice playback)
            if viewModel.note.hasActiveReminder || viewModel.note.hasActiveAlarm || viewModel.note.hasActiveTimer || viewModel.note.hasVoiceNote {
                statusChipsRow
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, 4)
            }

            // Integrated Floating Island Bottom Toolbar
            bottomToolbarSection(textColor: textColor, isDarkText: isDarkText)
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, 8)
                .layoutPriority(2)
        }
        .frame(minWidth: 260, maxWidth: .infinity, minHeight: 280, maxHeight: .infinity)
        .background(
            ZStack {
                bg

                // Gentle vertical illumination gradient
                LinearGradient(
                    colors: [
                        Color.white.opacity(isDarkText ? 0.22 : 0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )

                if viewModel.currentTheme == .paper {
                    Canvas { context, size in
                        var y: CGFloat = 40
                        while y < size.height {
                            var p = Path()
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(p, with: .color(Color.black.opacity(0.03)), lineWidth: 1)
                            y += 24
                        }
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            // Specular rim stroke
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDarkText ? 0.65 : 0.25),
                            Color.black.opacity(isDarkText ? 0.08 : 0.22)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.9
                )
        )
        .overlay(alignment: .bottomTrailing) {
            resizeGripView(textColor: secondaryColor)
        }
        .noteCardShadow()
        .tint(textColor.opacity(0.75))
        .onAppear {
            cleanEmptyChecklistItems()
        }
        .popover(item: $viewModel.activePopover) { popover in
            switch popover {
            case .color:
                ColorPickerPopoverView(viewModel: viewModel)
            case .reminder:
                ReminderPopoverView(viewModel: viewModel)
            case .alarm:
                AlarmPopoverView(viewModel: viewModel)
            case .timer:
                TimerPopoverView(viewModel: viewModel)
            case .calendar:
                CalendarPopoverView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Subviews

    private func topHeaderStrip(textColor: Color, secondaryColor: Color, isDarkText: Bool) -> some View {
        HStack(spacing: 6) {
            // Folder Tag Micro-Pill
            HStack(spacing: 4) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(textColor.opacity(0.65))

                Text(viewModel.note.folder)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor.opacity(0.75))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.black.opacity(isFolderHovered ? 0.09 : 0.05))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.black.opacity(0.04), lineWidth: 0.5)
            )
            .onHover { isFolderHovered = $0 }

            // All Notes & Stack Manager Button
            Button(action: { onOpenStackList?() }) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(secondaryColor.opacity(isStackHovered ? 0.95 : 0.70))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(isStackHovered ? 0.08 : 0.03))
                    )
                    .scaleEffect(isStackHovered ? 1.08 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isStackHovered)
            }
            .buttonStyle(.plain)
            .help("All Notes & Stack Manager (⌘L)")
            .onHover { isStackHovered = $0 }

            // Pin Button
            Button(action: { viewModel.togglePin() }) {
                if viewModel.note.isPinned {
                    HStack(spacing: 3) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(0.18))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.orange.opacity(0.25), lineWidth: 0.6)
                    )
                    .scaleEffect(isPinHovered ? 1.08 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPinHovered)
                } else {
                    Image(systemName: "pin")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(secondaryColor.opacity(isPinHovered ? 0.9 : 0.6))
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(isPinHovered ? 0.08 : 0.0))
                        )
                        .scaleEffect(isPinHovered ? 1.08 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPinHovered)
                }
            }
            .buttonStyle(.plain)
            .help(viewModel.note.isPinned ? "Unpin note" : "Pin note to top")
            .onHover { isPinHovered = $0 }

            Spacer()

            // Collapse Button
            Button(action: { viewModel.toggleCollapse() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(secondaryColor.opacity(isCollapseHovered ? 0.9 : 0.6))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(isCollapseHovered ? 0.08 : 0.0))
                    )
                    .scaleEffect(isCollapseHovered ? 1.08 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isCollapseHovered)
            }
            .buttonStyle(.plain)
            .help("Collapse to pill")
            .onHover { isCollapseHovered = $0 }

            // Close Button
            Button(action: { onClose?() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(isCloseHovered ? Color.red.opacity(0.9) : secondaryColor.opacity(0.6))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(isCloseHovered ? Color.red.opacity(0.12) : Color.black.opacity(0.0))
                    )
                    .scaleEffect(isCloseHovered ? 1.08 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isCloseHovered)
            }
            .buttonStyle(.plain)
            .help("Close note")
            .onHover { isCloseHovered = $0 }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.top, 10)
        .padding(.bottom, 2)
        .background(
            WindowDragArea(onDoubleClick: {
                viewModel.toggleCollapse()
            })
        )
        .onTapGesture(count: 2) {
            viewModel.toggleCollapse()
        }
        .contextMenu {
            Button("Collapse Note") {
                viewModel.toggleCollapse()
            }
            Divider()
            Button("Collapse All Notes (⌃⌥C)") {
                AppState.shared.collapseAllNotes()
            }
            Button("See All Notes (⌃⌥E)") {
                AppState.shared.expandAllNotes()
            }
            Divider()
            Button("All Notes & Stack Manager (⌘L)") {
                onOpenStackList?()
            }
            Divider()
            Button(viewModel.note.isPinned ? "Unpin Note" : "Pin Note") {
                viewModel.togglePin()
            }
            Button("Close Note") {
                onClose?()
            }
        }
    }

    private func titleEditor(textColor: Color) -> some View {
        let placeholderColor = viewModel.note.color.requiresDarkText
            ? Color(hex: "#6B7280")
            : Color(hex: "#9CA3AF")

        return TextField(
            "Title",
            text: Binding(
                get: { viewModel.note.title },
                set: { viewModel.updateTitle($0) }
            ),
            prompt: Text("Title").foregroundColor(placeholderColor)
        )
        .font(.system(size: 18, weight: .bold, design: .rounded))
        .tracking(-0.3)
        .textFieldStyle(.plain)
        .foregroundStyle(textColor)
        .tint(textColor)
        .accentColor(textColor)
        .focusEffectDisabled()
        .autocorrectionDisabled(true)
    }

    private func noteDateBadge(secondaryColor: Color, isDarkText: Bool) -> some View {
        Button(action: {
            viewModel.activePopover = .calendar
        }) {
            HStack(spacing: 5) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(secondaryColor.opacity(0.85))

                Text(viewModel.note.createdAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(secondaryColor.opacity(0.85))

                if viewModel.note.hasActiveReminder {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 4.5, height: 4.5)
                }

                if viewModel.note.hasActiveAlarm {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 4.5, height: 4.5)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 6.5, weight: .bold))
                    .foregroundColor(secondaryColor.opacity(0.4))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(
                Capsule()
                    .fill(Color.black.opacity(isDateHovered ? 0.08 : 0.04))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.black.opacity(0.04), lineWidth: 0.5)
            )
            .scaleEffect(isDateHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDateHovered)
        }
        .buttonStyle(.plain)
        .help("View calendar & schedule for this note")
        .onHover { isDateHovered = $0 }
    }

    private func bodyEditor(textColor: Color) -> some View {
        let placeholderColor = viewModel.note.color.requiresDarkText
            ? Color(hex: "#71717A")
            : Color(hex: "#A1A1AA")

        return TextField(
            "Write a note...",
            text: Binding(
                get: { viewModel.note.body },
                set: { viewModel.updateBody($0) }
            ),
            prompt: Text("Write a note...").foregroundColor(placeholderColor),
            axis: .vertical
        )
        .font(.system(size: 13.5, design: .rounded))
        .lineSpacing(4)
        .textFieldStyle(.plain)
        .foregroundStyle(textColor)
        .tint(textColor)
        .accentColor(textColor)
        .focusEffectDisabled()
        .frame(
            minHeight: (viewModel.note.body.isEmpty && viewModel.note.checklist.isEmpty) ? 80 : 32,
            alignment: .topLeading
        )
    }

    private func checklistSection(textColor: Color, isDarkText: Bool) -> some View {
        let placeholderColor = isDarkText
            ? Color(hex: "#71717A")
            : Color(hex: "#A1A1AA")

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(viewModel.note.checklist) { item in
                HStack(spacing: 8) {
                    // Tactile Squircle Checkbox
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                            viewModel.toggleChecklist(item: item)
                        }
                    }) {
                        ZStack {
                            if item.isDone {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 17, height: 17)
                                    .shadow(color: Color(hex: "#16A34A").opacity(0.35), radius: 2, y: 1)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundColor(.white)
                            } else {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.white.opacity(isDarkText ? 0.75 : 0.2))
                                    .frame(width: 17, height: 17)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .strokeBorder(textColor.opacity(0.32), lineWidth: 1.2)
                                    )
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Editable task description with high-contrast text
                    TextField(
                        "To-do",
                        text: Binding(
                            get: { item.text },
                            set: { viewModel.updateChecklistItem(id: item.id, text: $0) }
                        ),
                        prompt: Text("To-do").foregroundColor(placeholderColor)
                    )
                    .font(.system(size: 13, design: .rounded))
                    .textFieldStyle(.plain)
                    .foregroundStyle(item.isDone ? textColor.opacity(0.42) : textColor)
                    .tint(textColor)
                    .accentColor(textColor)
                    .strikethrough(item.isDone, color: textColor.opacity(0.35))
                    .focusEffectDisabled()
                    .onSubmit {
                        if !item.text.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.addChecklistItem(text: "")
                        }
                    }

                    Spacer()

                    // Subtle delete button shown on row hover
                    if hoveredTaskID == item.id {
                        Button(action: {
                            viewModel.removeChecklistItem(id: item.id)
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(textColor.opacity(0.65))
                                .frame(width: 18, height: 18)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Delete task")
                        .transition(.opacity)
                    } else {
                        Color.clear.frame(width: 18, height: 18)
                    }
                }
                .contentShape(Rectangle())
                .onHover { isHov in
                    hoveredTaskID = isHov ? item.id : nil
                }
            }

            // Clean "+ Add a task" button
            Button(action: {
                viewModel.addChecklistItem(text: "")
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textColor.opacity(0.75))
                    Text("Add a task")
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundColor(textColor.opacity(0.85))
                    Spacer()
                }
                .padding(.vertical, 3.5)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(isAddTaskHovered ? 0.05 : 0.0))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Add a new task")
            .onHover { isAddTaskHovered = $0 }
        }
    }

    private func cleanEmptyChecklistItems() {
        if viewModel.note.checklist.count > 1 {
            var seenEmpty = false
            var cleaned: [ChecklistItem] = []
            for item in viewModel.note.checklist {
                if item.text.trimmingCharacters(in: .whitespaces).isEmpty {
                    if !seenEmpty {
                        cleaned.append(item)
                        seenEmpty = true
                    }
                } else {
                    cleaned.append(item)
                }
            }
            if cleaned.count != viewModel.note.checklist.count {
                viewModel.note.checklist = cleaned
            }
        }
    }

    private var statusChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Reminder chip
                if let reminder = viewModel.note.reminder {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 9))
                        Text(reminder.targetDate.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.18))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.orange.opacity(0.25), lineWidth: 0.6)
                    )
                    .foregroundColor(.orange)
                    .onTapGesture {
                        viewModel.activePopover = .reminder
                    }
                }

                // Alarm chip
                if let alarm = viewModel.note.alarm, alarm.isEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 9))
                        Text(alarm.displayTimeString)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.18))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.purple.opacity(0.25), lineWidth: 0.6)
                    )
                    .foregroundColor(.purple)
                    .onTapGesture {
                        viewModel.activePopover = .alarm
                    }
                }

                // Timer Progress Chip
                if let timer = viewModel.note.timerSession {
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        HStack(spacing: 4) {
                            MascotFaceView(
                                mood: (timer.isRunning && !timer.isFinished(at: context.date)) ? .awake : .sleeping,
                                tint: .blue,
                                size: 16
                            )
                            Text(timer.formattedRemaining(at: context.date))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.blue.opacity(0.22), lineWidth: 0.6)
                        )
                        .foregroundColor(.blue)
                        .onTapGesture {
                            viewModel.activePopover = .timer
                        }
                    }
                }

                // Voice Playback Pill
                if let clip = viewModel.note.voiceClip {
                    VoicePlaybackPill(viewModel: viewModel, clip: clip)
                }
            }
            .padding(.vertical, 1)
        }
    }

    @ViewBuilder
    private func bottomToolbarSection(textColor: Color, isDarkText: Bool) -> some View {
        if viewModel.isRecordingAudio {
            VoiceRecorderBar(
                viewModel: viewModel,
                recorder: audioRecorder,
                transcriber: speechTranscriber
            )
            .frame(height: 32)
        } else {
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    // Reminder
                    toolbarIconButton(
                        id: "bell",
                        icon: "bell.fill",
                        color: .orange,
                        tooltip: "Set Reminder",
                        hasActiveState: viewModel.note.hasActiveReminder
                    ) {
                        viewModel.activePopover = .reminder
                    }

                    // Alarm
                    toolbarIconButton(
                        id: "alarm",
                        icon: "alarm.fill",
                        color: .purple,
                        tooltip: "Set Alarm",
                        hasActiveState: viewModel.note.hasActiveAlarm
                    ) {
                        viewModel.activePopover = .alarm
                    }

                    // Timer
                    toolbarIconButton(
                        id: "timer",
                        icon: "hourglass",
                        color: .blue,
                        tooltip: "Focus Timer",
                        hasActiveState: viewModel.note.hasActiveTimer
                    ) {
                        viewModel.activePopover = .timer
                    }

                    // Voice
                    toolbarIconButton(
                        id: "voice",
                        icon: "mic.fill",
                        color: Color(hex: "#FF4D6D"),
                        tooltip: "Record Voice Note",
                        hasActiveState: viewModel.note.hasVoiceNote
                    ) {
                        viewModel.isRecordingAudio = true
                    }

                    // Add task checklist
                    toolbarIconButton(
                        id: "task",
                        icon: "checklist",
                        color: Color(hex: "#2EB872"),
                        tooltip: "Add Checklist Task",
                        hasActiveState: viewModel.note.checklist.contains(where: { !$0.isDone })
                    ) {
                        viewModel.addChecklistItem(text: "")
                    }

                    // Calendar & Dates
                    toolbarIconButton(
                        id: "calendar",
                        icon: "calendar",
                        color: Color(hex: "#2563EB"),
                        tooltip: "Calendar & Dates",
                        hasActiveState: false
                    ) {
                        viewModel.activePopover = .calendar
                    }

                    // Subtle separator dot
                    Circle()
                        .fill(textColor.opacity(0.18))
                        .frame(width: 2.5, height: 2.5)
                        .padding(.horizontal, 2)

                    // Color Swatch
                    toolbarIconButton(
                        id: "color",
                        icon: "paintpalette.fill",
                        color: textColor.opacity(0.85),
                        tooltip: "Note Color",
                        hasActiveState: false
                    ) {
                        viewModel.activePopover = .color
                    }
                }
                .padding(.horizontal, 8)
                .frame(height: 30)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .background(
                    Capsule()
                        .fill(Color.white.opacity(isDarkText ? 0.88 : 0.22))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.85),
                                    Color.black.opacity(0.10)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                )
                .shadow(color: Color.black.opacity(0.04), radius: 1.5, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)

                Spacer(minLength: 0)
            }
        }
    }

    private func toolbarIconButton(
        id: String,
        icon: String,
        color: Color,
        tooltip: String,
        hasActiveState: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                // Soft hover halo
                if hoveredButton == id {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 24, height: 24)
                }

                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color)

                    if hasActiveState {
                        Circle()
                            .fill(color)
                            .frame(width: 3, height: 3)
                    }
                }
            }
            .frame(width: 25, height: 26)
            .scaleEffect(hoveredButton == id ? 1.18 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: hoveredButton)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { isHov in
            hoveredButton = isHov ? id : nil
        }
    }

    private func resizeGripView(textColor: Color) -> some View {
        ZStack {
            // Tactile 6-dot diagonal cluster
            Canvas { context, size in
                let dotColor = isResizeHovered ? textColor.opacity(0.85) : textColor.opacity(0.32)
                let dots = [
                    CGPoint(x: size.width - 5, y: size.height - 5),
                    CGPoint(x: size.width - 10, y: size.height - 5),
                    CGPoint(x: size.width - 5, y: size.height - 10),
                    CGPoint(x: size.width - 15, y: size.height - 5),
                    CGPoint(x: size.width - 10, y: size.height - 10),
                    CGPoint(x: size.width - 5, y: size.height - 15)
                ]
                for pt in dots {
                    let rect = CGRect(x: pt.x - 1, y: pt.y - 1, width: 2, height: 2)
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                }
            }
        }
        .frame(width: 22, height: 22)
        .contentShape(Rectangle())
        .padding(.trailing, 4)
        .padding(.bottom, 4)
        .help("Drag to resize note")
        .scaleEffect(isResizeHovered ? 1.1 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isResizeHovered)
        .onHover { isHov in
            isResizeHovered = isHov
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    let diff = CGSize(
                        width: gesture.translation.width - prevResizeTranslation.width,
                        height: gesture.translation.height - prevResizeTranslation.height
                    )
                    prevResizeTranslation = gesture.translation
                    onResize?(diff)
                }
                .onEnded { _ in
                    prevResizeTranslation = .zero
                }
        )
    }
}
