import SwiftUI
import AppKit

public struct FocusableTextView: View {

    @Binding private var text: String
    @State private var isFocused: Bool = false

    private let font: NSFont
    private let backgroundColor: Color
    private let cornerRadius: CGFloat
    private let contentInsets: NSEdgeInsets
    private let isDisabled: Bool

    public init(
        text: Binding<String>,
        font: NSFont = .systemFont(ofSize: NSFont.systemFontSize),
        backgroundColor: Color = Color(NSColor.systemFill).opacity(0.5),
        disabled: Bool = false,
        cornerRadius: CGFloat = 4,
        contentInsets: NSEdgeInsets = .init(top: 8, left: 4, bottom: 8, right: 4)
    ) {
        self._text = text
        self.font = font
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.contentInsets = contentInsets
        self.isDisabled = disabled
    }

    public var body: some View {
        FocusableTextViewRepresentable(
            text: $text,
            isFocused: $isFocused,
            font: font,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            contentInsets: contentInsets,
            isDisabled: isDisabled
        )
    }
}
