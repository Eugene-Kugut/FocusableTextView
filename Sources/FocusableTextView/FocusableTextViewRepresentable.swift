import SwiftUI
import AppKit

@MainActor
struct FocusableTextViewRepresentable: NSViewRepresentable {

    @Binding var text: String
    @Binding var isFocused: Bool

    let font: NSFont
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let contentInsets: NSEdgeInsets
    let isDisabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(configuration: self)
    }

    func makeNSView(context: Context) -> ContainerView {
        let containerView = ContainerView()
        containerView.cornerRadius = cornerRadius
        containerView.fillColor = NSColor(backgroundColor)

        let scrollView = ClickToFocusScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = KeyLoopTextView()
        textView.allowsKeyLoopFocus = !isDisabled
        textView.isEditable = !isDisabled

        textView.onBecameFirstResponder = { [weak coordinator = context.coordinator] in
            coordinator?.setFocusedFromAppKit(true)
        }
        textView.onResignedFirstResponder = { [weak coordinator = context.coordinator] in
            coordinator?.setFocusedFromAppKit(false)
        }

        textView.delegate = context.coordinator
        textView.string = text

        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.drawsBackground = false

        textView.font = font
        textView.textColor = .labelColor

        textView.textContainerInset = NSSize(
            width: contentInsets.left,
            height: contentInsets.top
        )

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )

        scrollView.documentView = textView
        containerView.embedContentView(scrollView)

        scrollView.requestFocus = { [weak textView, weak coordinator = context.coordinator] in
            guard let coordinator else { return }
            guard coordinator.configuration.isDisabled == false else { return }
            guard let textView else { return }

            textView.window?.makeFirstResponder(textView)
            coordinator.setFocusedFromAppKit(true)
        }

        containerView.onInstalledInWindow = { [weak containerView, weak coordinator = context.coordinator] in
            guard let containerView, let coordinator else { return }
            coordinator.installOutsideClickMonitor(for: containerView)

            containerView.layer?.setNeedsDisplay()
            containerView.needsDisplay = true
            containerView.needsLayout = true
        }

        containerView.onRemovedFromWindow = { [weak coordinator = context.coordinator] in
            coordinator?.removeOutsideClickMonitor()
        }

        context.coordinator.containerView = containerView
        context.coordinator.textView = textView

        containerView.needsDisplay = true
        containerView.needsLayout = true

        return containerView
    }

    func updateNSView(_ containerView: ContainerView, context: Context) {
        context.coordinator.configuration = self

        containerView.cornerRadius = cornerRadius
        containerView.fillColor = NSColor(backgroundColor)

        containerView.needsDisplay = true
        containerView.needsLayout = true
        containerView.layer?.setNeedsDisplay()

        if let textView = context.coordinator.textView {
            if textView.string != text { textView.string = text }
            if textView.font != font { textView.font = font }

            textView.textContainerInset = NSSize(
                width: contentInsets.left,
                height: contentInsets.top
            )

            textView.allowsKeyLoopFocus = !isDisabled
            textView.isEditable = !isDisabled
        }

        if isDisabled, context.coordinator.isTextViewFirstResponder {
            context.coordinator.dropFocus()
        }

        if isDisabled, context.coordinator.configuration.isFocused {
            context.coordinator.forceUnfocusedState()
        }

        context.coordinator.applyFocusIfNeeded()
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {

        var configuration: FocusableTextViewRepresentable

        weak var containerView: NSView?
        weak var textView: KeyLoopTextView?

        nonisolated(unsafe) private var outsideClickMonitorToken: Any?

        private var isApplyingFocus: Bool = false

        init(configuration: FocusableTextViewRepresentable) {
            self.configuration = configuration
        }

        deinit {
            let token = outsideClickMonitorToken
            if let token {
                Task { @MainActor in
                    NSEvent.removeMonitor(token)
                }
            }
        }

        var isTextViewFirstResponder: Bool {
            guard let textView, let window = textView.window else { return false }
            return window.firstResponder === textView
        }

        func dropFocus() {
            guard let textView, let window = textView.window else { return }
            if window.firstResponder === textView {
                window.makeFirstResponder(nil)
            }
        }

        func forceUnfocusedState() {
            if configuration.isFocused {
                configuration.isFocused = false
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let changedTextView = notification.object as? NSTextView else { return }
            if configuration.text != changedTextView.string {
                configuration.text = changedTextView.string
            }
        }

        func setFocusedFromAppKit(_ focused: Bool) {
            guard configuration.isDisabled == false else { return }
            guard isApplyingFocus == false else { return }
            guard configuration.isFocused != focused else { return }

            configuration.isFocused = focused
        }

        func applyFocusIfNeeded() {
            guard let textView, let window = textView.window else { return }

            if configuration.isDisabled {
                if window.firstResponder === textView {
                    window.makeFirstResponder(nil)
                }
                return
            }

            isApplyingFocus = true
            defer { isApplyingFocus = false }

            if configuration.isFocused {
                if window.firstResponder !== textView {
                    window.makeFirstResponder(textView)
                }
            } else if window.firstResponder === textView {
                window.makeFirstResponder(nil)
            }
        }

        func installOutsideClickMonitor(for observedView: NSView) {
            removeOutsideClickMonitor()

            guard let window = observedView.window,
                  let contentView = window.contentView
            else { return }

            func handleClick(_ event: NSEvent) {
                guard let textView else { return }
                guard window.firstResponder === textView else { return }

                let pointInContentView = contentView.convert(event.locationInWindow, from: nil)
                let observedRectInContentView = observedView.convert(observedView.bounds, to: contentView)

                if observedRectInContentView.contains(pointInContentView) { return }

                window.makeFirstResponder(nil)

                if configuration.isDisabled == false {
                    setFocusedFromAppKit(false)
                }
            }

            let token = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            ) { event in
                handleClick(event)
                return event
            }

            outsideClickMonitorToken = token
        }

        func removeOutsideClickMonitor() {
            if let token = outsideClickMonitorToken {
                NSEvent.removeMonitor(token)
                outsideClickMonitorToken = nil
            }
        }
    }
}
