import AppKit

@MainActor
final class ContainerView: NSView {

    var onInstalledInWindow: (() -> Void)?
    var onRemovedFromWindow: (() -> Void)?
    var onHoverChanged: ((Bool) -> Void)?

    var fillColor: NSColor = .clear
    var overlayColor: NSColor = .clear
    var overlayLineWidth: CGFloat = 0
    var cornerRadius: CGFloat = 0
    private var hoverTrackingArea: NSTrackingArea?
    private let overlayLayer = CAShapeLayer()

    override var wantsUpdateLayer: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        configureOverlayLayerIfNeeded()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        configureOverlayLayerIfNeeded()
    }

    override func updateLayer() {
        super.updateLayer()

        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = fillColor.cgColor
        }

        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true
        updateOverlayLayer()
    }

    func setFillColor(_ color: NSColor, animated: Bool, duration: CFTimeInterval = 0.18) {
        fillColor = color

        guard let layer = layer else {
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

    func setOverlay(color: NSColor, lineWidth: CGFloat) {
        overlayColor = color
        overlayLineWidth = lineWidth

        guard layer != nil else {
            needsDisplay = true
            return
        }

        configureOverlayLayerIfNeeded()
        updateOverlayLayer()
    }

    override func layout() {
        super.layout()
        updateOverlayLayer()
    }

    private func configureOverlayLayerIfNeeded() {
        guard let layer = layer else { return }
        guard overlayLayer.superlayer == nil else { return }

        overlayLayer.fillColor = NSColor.clear.cgColor
        overlayLayer.lineJoin = .round
        overlayLayer.lineCap = .round
        overlayLayer.actions = [
            "path": NSNull(),
            "lineWidth": NSNull(),
            "strokeColor": NSNull(),
            "bounds": NSNull(),
            "position": NSNull()
        ]
        layer.addSublayer(overlayLayer)
    }

    private func updateOverlayLayer() {
        guard layer != nil else { return }

        configureOverlayLayerIfNeeded()

        guard overlayLineWidth > 0 else {
            overlayLayer.path = nil
            overlayLayer.lineWidth = 0
            return
        }

        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        let minimumVisibleLineWidth = 1.0 / scale
        let effectiveLineWidth = max(overlayLineWidth, minimumVisibleLineWidth)
        let inset = effectiveLineWidth / 2.0
        let borderRect = bounds.insetBy(dx: inset, dy: inset)
        guard borderRect.width > 0, borderRect.height > 0 else {
            overlayLayer.path = nil
            return
        }

        var strokeColor = overlayColor.cgColor
        effectiveAppearance.performAsCurrentDrawingAppearance {
            strokeColor = overlayColor.cgColor
        }

        overlayLayer.frame = bounds
        overlayLayer.contentsScale = scale
        overlayLayer.strokeColor = strokeColor
        overlayLayer.lineWidth = effectiveLineWidth
        overlayLayer.path = CGPath(
            roundedRect: borderRect,
            cornerWidth: max(0, cornerRadius - inset),
            cornerHeight: max(0, cornerRadius - inset),
            transform: nil
        )
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
