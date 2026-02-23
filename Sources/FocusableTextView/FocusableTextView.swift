import SwiftUI
import AppKit

public struct FocusableTextView: View {

    @Binding private var text: String
    @State private var isFocused: Bool = false

    private let font: NSFont
    private let backgroundColor: Color
    private let focusedBackground: Color
    private let hoveredBackground: Color
    private let focusedOverlay: Color
    private let focusedOverlayLineWidth: CGFloat
    private let overlayColor: Color
    private let overlayLineWidth: CGFloat
    private let cornerRadius: CGFloat
    private let contentInsets: NSEdgeInsets
    private let isDisabled: Bool
    private let singleLine: Bool

    public init(
        text: Binding<String>,
        font: NSFont = .systemFont(ofSize: NSFont.systemFontSize),

        backgroundColor: Color = Color(NSColor.systemFill).opacity(0.5),
        focusedBackground: Color = Color(NSColor.systemFill).opacity(0.5),
        hoveredBackground: Color = Color(NSColor.systemFill).opacity(0.7),

        focusedOverlay: Color = Color.accentColor.opacity(0.9),
        focusedOverlayLineWidth: CGFloat = 1.5,

        overlayColor: Color = .clear,
        overlayLineWidth: CGFloat = 1 / 3,

        disabled: Bool = false,
        singleLine: Bool = false,
        cornerRadius: CGFloat = 4,
        contentInsets: NSEdgeInsets = .init(top: 8, left: 4, bottom: 8, right: 4)
    ) {
        self._text = text
        self.font = font
        self.backgroundColor = backgroundColor
        self.focusedBackground = focusedBackground
        self.hoveredBackground = hoveredBackground
        self.focusedOverlay = focusedOverlay
        self.focusedOverlayLineWidth = focusedOverlayLineWidth
        self.overlayColor = overlayColor
        self.overlayLineWidth = overlayLineWidth
        self.cornerRadius = cornerRadius
        self.contentInsets = contentInsets
        self.isDisabled = disabled
        self.singleLine = singleLine
    }

    public var body: some View {
        FocusableTextViewRepresentable(
            text: $text,
            isFocused: $isFocused,
            font: font,
            backgroundColor: backgroundColor,
            focusedBackground: focusedBackground,
            hoveredBackground: hoveredBackground,
            focusedOverlay: focusedOverlay,
            focusedOverlayLineWidth: focusedOverlayLineWidth,
            overlayColor: overlayColor,
            overlayLineWidth: overlayLineWidth,
            cornerRadius: cornerRadius,
            contentInsets: contentInsets,
            isDisabled: isDisabled,
            singleLine: singleLine
        )
    }
}
