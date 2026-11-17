import SwiftUI

struct FullScreenPhotoView: View {
    @Environment(\.palette) private var palette
    let fileName: String
    var onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            palette.canvas.ignoresSafeArea()
            StoredImage(fileName: fileName, contentMode: .fit)
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(palette.text)
                    .frame(width: 40, height: 40)
                    .background(palette.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(20)
        }
    }
}
