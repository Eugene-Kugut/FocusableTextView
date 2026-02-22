import SwiftUI

struct DemoView: View {

    @State private var text: String = ""
    var body: some View {
        ZStack(content: {
            Color(NSColor.systemFill).edgesIgnoringSafeArea(.all)
            FocusableTextView(
                text: $text,
                backgroundColor: .white.opacity(0.8),
            )
            .padding()
        })
    }
}

#Preview {
    DemoView()
}
