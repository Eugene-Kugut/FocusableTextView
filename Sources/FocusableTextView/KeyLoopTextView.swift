import AppKit

@MainActor
final class KeyLoopTextView: NSTextView {

    var onBecameFirstResponder: (() -> Void)?
    var onResignedFirstResponder: (() -> Void)?
    var allowsKeyLoopFocus: Bool = true

    override var acceptsFirstResponder: Bool {
        allowsKeyLoopFocus
    }

    override func becomeFirstResponder() -> Bool {
        guard allowsKeyLoopFocus else { return false }
        let didBecome = super.becomeFirstResponder()
        if didBecome { onBecameFirstResponder?() }
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
}
