import SwiftUI

struct StoredImage: View {
    let fileName: String?
    var remoteURL: String? = nil
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let fileName, PhotoService.isReference(fileName) {
                CachedPhotoView(reference: fileName, contentMode: contentMode)
            } else if let remoteURL, let url = URL(string: remoteURL), !remoteURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: contentMode)
                    default:
                        Color(hex: 0xF3F4F6)
                    }
                }
            } else {
                Color(hex: 0xF3F4F6)
            }
        }
    }
}
