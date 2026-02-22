import SwiftUI

struct DemoView: View {

    @State private var text: String = ""
    var body: some View {
        ZStack(content: {
            Color(NSColor.systemFill).edgesIgnoringSafeArea(.all)
            VStack(content: {
                FocusableTextView(
                    text: $text,
                    backgroundColor: .white.opacity(0.5),
                    focusedBackground: .white,
                    hoveredBackground: .white
                )
                .padding()
                FocusableTextView(
                    text: $text,
                    backgroundColor: .white.opacity(0.5),
                    focusedBackground: .white,
                    hoveredBackground: .white
                )
                .padding()
            })
        })
    }
}

#Preview {
    DemoView()
}
