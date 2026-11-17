import SwiftUI

struct AppCard<Content: View>: View {
    @Environment(\.palette) private var palette
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sakayCardChrome(palette)
    }
}
