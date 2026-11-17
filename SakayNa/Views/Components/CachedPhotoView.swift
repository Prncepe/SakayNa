import SwiftUI

struct CachedPhotoView: View {
    @Environment(\.palette) private var palette
    let reference: String
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image = image ?? PhotoService.cachedImage(reference) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if failed {
                ZStack {
                    palette.fieldFill
                    Image(systemName: "photo")
                        .foregroundStyle(palette.muted)
                }
            } else {
                ZStack {
                    palette.fieldFill
                    ProgressView()
                        .tint(palette.yellow)
                }
            }
        }
        .task(id: reference) {
            failed = false
            do {
                image = try await PhotoService.load(reference)
                failed = image == nil
            } catch {
                failed = true
            }
        }
    }
}
