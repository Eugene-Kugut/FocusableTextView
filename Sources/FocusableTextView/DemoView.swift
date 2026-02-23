import SwiftUI

struct DemoView: View {

    @State private var text1: String = ""
    @State private var text2: String = ""
    var body: some View {
        ZStack(content: {
            Color(NSColor.systemFill).edgesIgnoringSafeArea(.all)
            VStack(content: {
                FocusableTextView(
                    text: $text1,
                    backgroundColor: .white.opacity(0.5),
                    focusedBackground: .white,
                    hoveredBackground: .white,
                    focusedOverlay: .blue,
                    focusedOverlayLineWidth: 1,
                    overlayColor: .gray,
                    overlayLineWidth: 1 / 6,
                    singleLine: true,
                    cornerRadius: 8
                )
                .padding()
                FocusableTextView(
                    text: $text2,
                    font: .systemFont(ofSize: 16, weight: .light),
                    backgroundColor: .white.opacity(0.5),
                    focusedBackground: .white,
                    hoveredBackground: .white,
                    focusedOverlay: .blue,
                    focusedOverlayLineWidth: 1,
                    overlayColor: .gray,
                    overlayLineWidth: 1 / 6,
                    cornerRadius: 8
                )
                .padding()
            })
        })
    }
}

#Preview {
    DemoView()
}
