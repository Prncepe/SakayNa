import SwiftUI

struct BrandMark: View {
    var size: CGFloat = 36

    var body: some View {
        // User logo used in the small top-left across the app
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("SakayNa")
    }
}
