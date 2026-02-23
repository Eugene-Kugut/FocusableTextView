import SwiftUI
import AppKit

@MainActor
struct FocusableTextViewRepresentable: NSViewRepresentable {

    @Binding var text: String
    @Binding var isFocused: Bool

    let font: NSFont

    let backgroundColor: Color
    let focusedBackground: Color
    let hoveredBackground: Color

    let focusedOverlay: Color
    let focusedOverlayLineWidth: CGFloat

    let overlayColor: Color
    let overlayLineWidth: CGFloat

    let cornerRadius: CGFloat
    let contentInsets: NSEdgeInsets
    let isDisabled: Bool
    let singleLine: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(configuration: self)
    }

    func makeNSView(context: Context) -> ContainerView {
        let containerView = ContainerView()
        containerView.cornerRadius = cornerRadius
        containerView.fillColor = NSColor(backgroundColor)
        containerView.overlayColor = NSColor(overlayColor)
        containerView.overlayLineWidth = overlayLineWidth
        containerView.onHoverChanged = { [weak coordinator = context.coordinator] isHovering in
            coordinator?.setHovering(isHovering)
        }

        let scrollView = ClickToFocusScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = KeyLoopTextView()
        textView.allowsKeyLoopFocus = !isDisabled
        textView.isEditable = !isDisabled

        textView.onBecameFirstResponder = { [weak coordinator = context.coordinator] acquisition in
            coordinator?.setFocusedFromAppKit(true, acquisition: acquisition)
        }
        textView.onResignedFirstResponder = { [weak coordinator = context.coordinator] in
            coordinator?.setFocusedFromAppKit(false)
        }
        textView.onMouseInteraction = { [weak coordinator = context.coordinator] in
            coordinator?.setMouseInteractionInsideFocusedControl()
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
        context.coordinator.applyBackground()
        context.coordinator.applyOverlay()

        return containerView
    }

    func updateNSView(_ containerView: ContainerView, context: Context) {
        context.coordinator.configuration = self

        containerView.cornerRadius = cornerRadius

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
        context.coordinator.applyBackground()
        context.coordinator.applyOverlay()
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {

        var configuration: FocusableTextViewRepresentable

        weak var containerView: ContainerView?
        weak var textView: KeyLoopTextView?

        nonisolated(unsafe) private var outsideClickMonitorToken: Any?

        private var isApplyingFocus: Bool = false
        private var isHovering: Bool = false
        private var isFocusedByTabNavigation: Bool = false
        private var lastAppliedFillColor: NSColor?
        private var lastAppliedOverlayColor: NSColor?
        private var lastAppliedOverlayLineWidth: CGFloat?

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

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard configuration.singleLine else { return false }

            if commandSelector == #selector(NSResponder.insertNewline(_:)) ||
                commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
                textView.selectAll(nil)
                return true
            }

            return false
        }

        func setFocusedFromAppKit(
            _ focused: Bool,
            acquisition: KeyLoopTextView.FocusAcquisition = .other
        ) {
            guard configuration.isDisabled == false else { return }
            guard isApplyingFocus == false else { return }

            if focused {
                isFocusedByTabNavigation = (acquisition == .tabNavigation)
            } else {
                isFocusedByTabNavigation = false
            }

            guard configuration.isFocused != focused else {
                applyOverlay()
                return
            }

            configuration.isFocused = focused
            applyBackground()
            applyOverlay()
        }

        func setMouseInteractionInsideFocusedControl() {
            guard configuration.isDisabled == false else { return }
            guard configuration.isFocused else { return }

            isFocusedByTabNavigation = false
            applyOverlay()
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
                isFocusedByTabNavigation = false
                applyOverlay()
            }
        }

        func setHovering(_ hovering: Bool) {
            guard isHovering != hovering else { return }
            isHovering = hovering
            applyBackground()
        }

        func applyBackground() {
            guard let containerView else { return }

            let color: Color
            if configuration.isFocused {
                color = configuration.focusedBackground
            } else if isHovering {
                color = configuration.hoveredBackground
            } else {
                color = configuration.backgroundColor
            }

            let resolvedColor = NSColor(color)
            guard lastAppliedFillColor?.isEqual(resolvedColor) != true else { return }

            let shouldAnimate = lastAppliedFillColor != nil
            lastAppliedFillColor = resolvedColor
            containerView.setFillColor(resolvedColor, animated: shouldAnimate)
        }

        func applyOverlay() {
            guard let containerView else { return }

            let color: Color
            let lineWidth: CGFloat

            if configuration.isFocused && isFocusedByTabNavigation {
                color = configuration.focusedOverlay
                lineWidth = configuration.focusedOverlayLineWidth
            } else {
                color = configuration.overlayColor
                lineWidth = configuration.overlayLineWidth
            }

            let resolvedColor = NSColor(color)
            let didChangeColor = lastAppliedOverlayColor?.isEqual(resolvedColor) != true
            let didChangeLineWidth = lastAppliedOverlayLineWidth != lineWidth
            guard didChangeColor || didChangeLineWidth else { return }

            lastAppliedOverlayColor = resolvedColor
            lastAppliedOverlayLineWidth = lineWidth
            containerView.setOverlay(color: resolvedColor, lineWidth: lineWidth)
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
                    setFocusedFromAppKit(false, acquisition: .other)
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
