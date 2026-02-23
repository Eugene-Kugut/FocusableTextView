import AppKit

@MainActor
final class KeyLoopTextView: NSTextView {

    enum FocusAcquisition {
        case tabNavigation
        case other
    }

    var onBecameFirstResponder: ((FocusAcquisition) -> Void)?
    var onResignedFirstResponder: (() -> Void)?
    var onMouseInteraction: (() -> Void)?
    var allowsKeyLoopFocus: Bool = true

    override var acceptsFirstResponder: Bool {
        allowsKeyLoopFocus
    }

    override func becomeFirstResponder() -> Bool {
        guard allowsKeyLoopFocus else { return false }
        let didBecome = super.becomeFirstResponder()
        if didBecome {
            onBecameFirstResponder?(focusAcquisitionFromCurrentEvent())
        }
        return didBecome
    }

    override func resignFirstResponder() -> Bool {
        let didResign = super.resignFirstResponder()
        if didResign { onResignedFirstResponder?() }
        return didResign
    }

    override func insertTab(_ sender: Any?) {
        window?.selectNextKeyView(sender)
    }

    override func insertBacktab(_ sender: Any?) {
        window?.selectPreviousKeyView(sender)
    }

    override func mouseDown(with event: NSEvent) {
        onMouseInteraction?()
        super.mouseDown(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        onMouseInteraction?()
        super.rightMouseDown(with: event)
    }

    override func otherMouseDown(with event: NSEvent) {
        onMouseInteraction?()
        super.otherMouseDown(with: event)
    }

    private func focusAcquisitionFromCurrentEvent() -> FocusAcquisition {
        guard let event = NSApp.currentEvent else { return .other }
        guard event.type == .keyDown else { return .other }

        if event.keyCode == 48 || event.charactersIgnoringModifiers == "\t" {
            return .tabNavigation
        }

        return .other
    }
}
