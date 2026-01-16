import AppKit

@MainActor
final class ClickToFocusScrollView: NSScrollView {

    var requestFocus: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        requestFocus?()
        super.mouseDown(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        requestFocus?()
        super.rightMouseDown(with: event)
    }

    override func otherMouseDown(with event: NSEvent) {
        requestFocus?()
        super.otherMouseDown(with: event)
    }
}
