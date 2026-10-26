import AppKit
import SwiftUI

public struct SubtleNoteTextView: NSViewRepresentable {
    @Binding public var text: String
    public var textColor: NSColor
    public var placeholder: String
    public var onCommit: (() -> Void)?

    public init(
        text: Binding<String>,
        textColor: NSColor,
        placeholder: String = "Write a note...",
        onCommit: (() -> Void)? = nil
    ) {
        _text = text
        self.textColor = textColor
        self.placeholder = placeholder
        self.onCommit = onCommit
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> InnerTextView {
        let textView = InnerTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.allowsUndo = true
        textView.placeholderString = placeholder
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 0, height: 4)

        // Set rounded font
        let roundedFont: NSFont
        if let desc = NSFont.systemFont(ofSize: 13.5, weight: .regular).fontDescriptor.withDesign(.rounded),
           let font = NSFont(descriptor: desc, size: 13.5) {
            roundedFont = font
        } else {
            roundedFont = NSFont.systemFont(ofSize: 13.5, weight: .regular)
        }
        textView.font = roundedFont

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3.5

        textView.typingAttributes = [
            .font: roundedFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.selectedTextAttributes = [
            .backgroundColor: textColor.withAlphaComponent(0.2),
            .foregroundColor: textColor
        ]

        textView.string = text
        context.coordinator.textView = textView

        return textView
    }

    public func updateNSView(_ textView: InnerTextView, context: Context) {
        // Update placeholder
        textView.placeholderString = placeholder

        // Update colors
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.selectedTextAttributes = [
            .backgroundColor: textColor.withAlphaComponent(0.2),
            .foregroundColor: textColor
        ]

        let roundedFont = textView.font ?? NSFont.systemFont(ofSize: 13.5, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3.5

        textView.typingAttributes = [
            .font: roundedFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        if textView.string != text, !context.coordinator.isEditing {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            textView.invalidateIntrinsicContentSize()
        }

        textView.needsDisplay = true
    }

    public final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SubtleNoteTextView
        weak var textView: InnerTextView?
        var isEditing = false

        init(_ parent: SubtleNoteTextView) {
            self.parent = parent
        }

        public func textDidBeginEditing(_: Notification) {
            isEditing = true
        }

        public func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? InnerTextView else { return }
            parent.text = tv.string
            tv.invalidateIntrinsicContentSize()
        }

        public func textDidEndEditing(_: Notification) {
            isEditing = false
            parent.onCommit?()
        }
    }
}

public final class InnerTextView: NSTextView {
    public var placeholderString: String = ""

    override public var intrinsicContentSize: NSSize {
        guard let layoutManager = layoutManager, let textContainer = textContainer else {
            return NSSize(width: NSView.noIntrinsicMetric, height: 60)
        }
        layoutManager.ensureLayout(for: textContainer)
        let used = layoutManager.usedRect(for: textContainer)
        return NSSize(width: NSView.noIntrinsicMetric, height: max(60, ceil(used.height) + 10))
    }

    override public func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if string.isEmpty, !placeholderString.isEmpty {
            let font = self.font ?? NSFont.systemFont(ofSize: 13.5)
            let placeholderColor = (textColor ?? NSColor.textColor).withAlphaComponent(0.4)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: placeholderColor
            ]
            let rect = NSRect(
                x: textContainerInset.width + 4,
                y: textContainerInset.height,
                width: bounds.width - 8,
                height: 20
            )
            (placeholderString as NSString).draw(in: rect, withAttributes: attrs)
        }
    }
}
