import AppKit

@MainActor
final class ContainerView: NSView {

    var onInstalledInWindow: (() -> Void)?
    var onRemovedFromWindow: (() -> Void)?
    var onHoverChanged: ((Bool) -> Void)?

    var fillColor: NSColor = .clear
    var cornerRadius: CGFloat = 0
    private var hoverTrackingArea: NSTrackingArea?

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

    func setFillColor(_ color: NSColor, animated: Bool, duration: CFTimeInterval = 0.18) {
        fillColor = color

        guard let layer else {
            needsDisplay = true
            return
        }

        var targetBackgroundColor: CGColor?
        effectiveAppearance.performAsCurrentDrawingAppearance {
            targetBackgroundColor = color.cgColor
        }
        guard let targetBackgroundColor else { return }

        if animated {
            let currentBackgroundColor = (layer.presentation() ?? layer).backgroundColor ?? layer.backgroundColor
            let animation = CABasicAnimation(keyPath: "backgroundColor")
            animation.fromValue = currentBackgroundColor
            animation.toValue = targetBackgroundColor
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(animation, forKey: "FocusableTextViewBackgroundTransition")
        }

        layer.backgroundColor = targetBackgroundColor
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil {
            onInstalledInWindow?()
        } else {
            onRemovedFromWindow?()
            onHoverChanged?(false)
        }

        layer?.setNeedsDisplay()
        needsDisplay = true
        needsLayout = true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let hoverTrackingArea {
            removeTrackingArea(hoverTrackingArea)
        }

        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .inVisibleRect
        ]

        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
        hoverTrackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        onHoverChanged?(false)
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
