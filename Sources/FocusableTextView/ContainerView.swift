import AppKit

@MainActor
final class ContainerView: NSView {

    var onInstalledInWindow: (() -> Void)?
    var onRemovedFromWindow: (() -> Void)?

    var fillColor: NSColor = .clear
    var cornerRadius: CGFloat = 0

    override var wantsUpdateLayer: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func updateLayer() {
        super.updateLayer()

        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = fillColor.cgColor
        }

        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil {
            onInstalledInWindow?()
        } else {
            onRemovedFromWindow?()
        }

        layer?.setNeedsDisplay()
        needsDisplay = true
        needsLayout = true
    }

    func embedContentView(_ view: NSView) {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
