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
    @State private var peekDismissTask: Task<Void, Never>?

    private func updateHoverState(pill: Bool? = nil, popover: Bool? = nil) {
        if let pill = pill { isPillHovered = pill }
        if let popover = popover { isPopoverHovered = popover }

        peekDismissTask?.cancel()
        if isPillHovered || isPopoverHovered {
            isHoveredPeek = true
        } else {
            peekDismissTask = Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
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

        return HStack(spacing: 4.5) {
            // Icon: timer, reminder, or color dot
            if viewModel.note.hasActiveTimer {
                Image(systemName: "hourglass")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.blue)
            } else if viewModel.note.hasActiveReminder {
                Image(systemName: "bell.fill")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.orange)
            } else {
                Circle()
                    .fill(Color(hex: viewModel.note.color.hex))
                    .frame(width: 7.5, height: 7.5)
                    .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 0.8))
            }

            // Small title prefix
            Text(titlePrefix)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .lineLimit(1)

            Spacer(minLength: 0)

            // Mini chevron indicator
            Image(systemName: "chevron.up")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(textColor.opacity(0.45))
        }
        .padding(.horizontal, 6.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Capsule().fill(bg)
                WindowDragArea(onDoubleClick: {
                    isHoveredPeek = false
                    viewModel.toggleCollapse()
                })
            }
        )
        .overlay(
            Capsule()
                .stroke(Color.black.opacity(0.12), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 2.5, x: 0, y: 1.2)
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
            collapsedHoverInfoCard(textColor: textColor, bg: bg)
                .onHover { isHov in
                    updateHoverState(popover: isHov)
                }
        }
        .help(hoverTooltipSummary)
    }

    private func collapsedHoverInfoCard(textColor: Color, bg: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: viewModel.note.color.hex))
                    .frame(width: 8.5, height: 8.5)
                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 0.8))

                Text(viewModel.note.title.isEmpty ? "Untitled Note" : viewModel.note.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
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
                    .padding(.horizontal, 6.5)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("All Notes (Stack Manager - ⌘L)")

                // Expand button
                Button(action: {
                    isHoveredPeek = false
                    viewModel.toggleCollapse()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(textColor.opacity(0.75))
                        .frame(width: 20, height: 20)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
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
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "#2EB872"))
                    Text("\(doneCount) of \(viewModel.note.checklist.count) tasks done")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(textColor.opacity(0.75))
                }
            }

            if let timer = viewModel.note.timerSession {
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 9))
                        .foregroundColor(.blue)
                    Text("Focus: \(timer.formattedRemaining(at: Date()))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                }
            }

            if let rem = viewModel.note.reminder {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text("Reminder: \(rem.targetDate.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(10)
        .frame(width: 220)
        .background(bg.opacity(0.97))
        .onTapGesture(count: 2) {
            isHoveredPeek = false
            viewModel.toggleCollapse()
        }
    }

    private var collapsedMiniView: some View {
        let bg = PetalColor.resolve(noteColor: viewModel.note.color, theme: viewModel.currentTheme)
        let textColor = PetalColor.textColor(for: viewModel.note.color, theme: viewModel.currentTheme)

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
                    Image(systemName: "bell.fill")
                        .font(.system(size: 8.5))
                        .foregroundColor(.orange)
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
                WindowDragArea(onDoubleClick: {
                    viewModel.toggleCollapse()
                })
            }
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1.5)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            viewModel.toggleCollapse()
        }
    }

    // MARK: - Expanded Card View

    private var expandedCardView: some View {
        let bg = PetalColor.resolve(noteColor: viewModel.note.color, theme: viewModel.currentTheme)
        let textColor = PetalColor.textColor(for: viewModel.note.color, theme: viewModel.currentTheme)
        let secondaryColor = PetalColor.secondaryTextColor(for: viewModel.note.color, theme: viewModel.currentTheme)

        return VStack(alignment: .leading, spacing: 0) {
            // Top Strip (Clean Drag Bar)
            topHeaderStrip(textColor: textColor, secondaryColor: secondaryColor)

            // Title Field
            titleEditor(textColor: textColor, secondaryColor: secondaryColor)
                .padding(.horizontal, Spacing.m)
                .padding(.top, 6)

            // Body & Checklist
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    bodyEditor(textColor: textColor)

                    if !viewModel.note.checklist.isEmpty {
                        checklistSection(textColor: textColor, secondaryColor: secondaryColor)
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, 4)
                .padding(.bottom, 6)
            }

            // Status Chips (Reminder, Timer, Voice playback)
            if viewModel.note.hasActiveReminder || viewModel.note.hasActiveTimer || viewModel.note.hasVoiceNote {
                statusChipsRow
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, 3)
            }

            // Integrated Bottom Toolbar
            bottomToolbarSection(textColor: textColor)
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, 7)
        }
        .frame(minWidth: 248, minHeight: 150, maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                bg
                if viewModel.currentTheme == .paper {
                    Canvas { context, size in
                        var y: CGFloat = 40
                        while y < size.height {
                            var p = Path()
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(p, with: .color(Color.black.opacity(0.035)), lineWidth: 1)
                            y += 24
                        }
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.8)
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
            }
        }
    }

    // MARK: - Subviews

    private func topHeaderStrip(textColor: Color, secondaryColor: Color) -> some View {
        HStack(spacing: 8) {
            // Folder Tag Pill
            Text(viewModel.note.folder)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(textColor.opacity(0.7))
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.black.opacity(0.06))
                .clipShape(Capsule())

            // All Notes & Stack Manager Button
            Button(action: { onOpenStackList?() }) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(secondaryColor.opacity(0.75))
                    .frame(width: 20, height: 20)
                    .background(Color.black.opacity(0.04))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("All Notes (Stack Manager & Search)")

            // Pin Button
            Button(action: { viewModel.togglePin() }) {
                Image(systemName: viewModel.note.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.note.isPinned ? .orange : secondaryColor.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help(viewModel.note.isPinned ? "Unpin from top" : "Pin to top")

            Spacer()

            // Collapse Button
            Button(action: { viewModel.toggleCollapse() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(secondaryColor.opacity(0.6))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Collapse to pill")

            // Close Note Button
            Button(action: { onClose?() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(secondaryColor.opacity(0.6))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Close note")
        }
        .padding(.horizontal, Spacing.m)
        .padding(.top, Spacing.s)
        .padding(.bottom, 2)
        .background(
            WindowDragArea(onDoubleClick: {
                viewModel.toggleCollapse()
            })
        )
        .onTapGesture(count: 2) {
            viewModel.toggleCollapse()
        }
    }

    private func titleEditor(textColor: Color, secondaryColor _: Color) -> some View {
        let placeholderColor = viewModel.note.color.requiresDarkText
            ? Color(hex: "#6B7280")
            : Color(hex: "#9CA3AF")

        return TextField("Title", text: Binding(
            get: { viewModel.note.title },
            set: { viewModel.updateTitle($0) }
        ), prompt: Text("Title").foregroundColor(placeholderColor))
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .textFieldStyle(.plain)
            .foregroundStyle(textColor)
            .tint(textColor)
            .accentColor(textColor)
            .focusEffectDisabled()
            .autocorrectionDisabled(true)
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
        .lineSpacing(3.5)
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

    private func checklistSection(textColor: Color, secondaryColor _: Color) -> some View {
        let placeholderColor = viewModel.note.color.requiresDarkText
            ? Color(hex: "#71717A")
            : Color(hex: "#A1A1AA")

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(viewModel.note.checklist) { item in
                HStack(spacing: 8) {
                    // Tactile Soft Checkbox
                    Button(action: { viewModel.toggleChecklist(item: item) }) {
                        ZStack {
                            if item.isDone {
                                RoundedRectangle(cornerRadius: 4.5)
                                    .fill(Color(hex: "#2EB872"))
                                    .frame(width: 16, height: 16)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8.5, weight: .heavy))
                                    .foregroundColor(.white)
                            } else {
                                RoundedRectangle(cornerRadius: 4.5)
                                    .strokeBorder(textColor.opacity(0.35), lineWidth: 1.2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4.5)
                                            .fill(Color.white.opacity(viewModel.note.color.requiresDarkText ? 0.75 : 0.2))
                                    )
                                    .frame(width: 16, height: 16)
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
                    .foregroundStyle(item.isDone ? textColor.opacity(0.4) : textColor)
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
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(textColor.opacity(0.55))
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)
                        .help("Delete task")
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
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(textColor.opacity(0.75))
                    Text("Add a task")
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundColor(textColor.opacity(0.85))
                    Spacer()
                }
                .padding(.vertical, 3.5)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Add a new task")
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
        HStack(spacing: 6) {
            // Reminder chip
            if let reminder = viewModel.note.reminder {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 9))
                    Text(reminder.targetDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.18))
                .foregroundColor(.orange)
                .cornerRadius(10)
                .onTapGesture {
                    viewModel.activePopover = .reminder
                }
            }

            // Timer Progress Chip
            if let timer = viewModel.note.timerSession {
                HStack(spacing: 4) {
                    MascotFaceView(
                        mood: timer.isRunning ? .awake : .sleeping,
                        tint: .blue,
                        size: 16
                    )
                    Text(timer.formattedRemaining(at: Date()))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .cornerRadius(10)
                .onTapGesture {
                    viewModel.activePopover = .timer
                }
            }

            // Voice Playback Pill
            if let clip = viewModel.note.voiceClip {
                VoicePlaybackPill(viewModel: viewModel, clip: clip)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func bottomToolbarSection(textColor: Color) -> some View {
        if viewModel.isRecordingAudio {
            VoiceRecorderBar(
                viewModel: viewModel,
                recorder: audioRecorder,
                transcriber: speechTranscriber
            )
            .frame(height: 30)
        } else {
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    // Reminder
                    toolbarIconButton(id: "bell", icon: "bell.fill", color: .orange, tooltip: "Set Reminder") {
                        viewModel.activePopover = .reminder
                    }

                    // Alarm
                    toolbarIconButton(id: "alarm", icon: "alarm.fill", color: .purple, tooltip: "Set Alarm") {
                        viewModel.activePopover = .alarm
                    }

                    // Timer
                    toolbarIconButton(id: "timer", icon: "hourglass", color: .blue, tooltip: "Focus Timer") {
                        viewModel.activePopover = .timer
                    }

                    // Voice
                    toolbarIconButton(
                        id: "voice",
                        icon: "mic.fill",
                        color: Color(hex: "#FF4D6D"),
                        tooltip: "Record Voice Note"
                    ) {
                        viewModel.isRecordingAudio = true
                    }

                    // Add task checklist
                    toolbarIconButton(
                        id: "task",
                        icon: "checklist",
                        color: Color(hex: "#2EB872"),
                        tooltip: "Add Checklist Task"
                    ) {
                        viewModel.addChecklistItem(text: "")
                    }

                    // Subtle separator dot
                    Circle()
                        .fill(textColor.opacity(0.2))
                        .frame(width: 2.5, height: 2.5)
                        .padding(.horizontal, 2)

                    // Color Swatch
                    toolbarIconButton(
                        id: "color",
                        icon: "paintpalette.fill",
                        color: textColor.opacity(0.85),
                        tooltip: "Note Color"
                    ) {
                        viewModel.activePopover = .color
                    }
                }
                .padding(.horizontal, 7)
                .frame(height: 28)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(viewModel.note.color.requiresDarkText ? 0.92 : 0.24))
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.08), lineWidth: 0.6)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1.2)
                )

                Spacer(minLength: 0)
            }
        }
    }

    private func toolbarIconButton(
        id: String,
        icon: String,
        color: Color,
        tooltip: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(hoveredButton == id ? Color.black.opacity(0.08) : Color.clear)
                    .frame(width: 22, height: 22)

                Image(systemName: icon)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(color)
            }
            .frame(width: 24, height: 24)
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
            Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                .font(.system(size: 8.5, weight: .bold))
                .foregroundColor(isResizeHovered ? textColor.opacity(0.75) : textColor.opacity(0.35))
        }
        .frame(width: 22, height: 22)
        .contentShape(Rectangle())
        .padding(.trailing, 3)
        .padding(.bottom, 3)
        .help("Drag to resize note")
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
