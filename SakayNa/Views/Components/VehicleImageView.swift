import SwiftUI

struct VehicleImageView: View {
    @Environment(\.palette) private var palette
    var imageName: String
    var customImageFile: String?
    var height: CGFloat

    init(vehicle: Vehicle, height: CGFloat = 110) {
        self.imageName = vehicle.imageName
        self.customImageFile = vehicle.coverFile ?? vehicle.customImageFile
        self.height = height
    }

    init(imageName: String, customImageFile: String?, height: CGFloat = 110) {
        self.imageName = imageName
        self.customImageFile = customImageFile
        self.height = height
    }

    var body: some View {
        Group {
            if let customImageFile, PhotoService.isReference(customImageFile) {
                CachedPhotoView(reference: customImageFile, contentMode: .fit)
            } else if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "car.fill")
                    .font(.system(size: height * 0.35))
                    .foregroundStyle(palette.muted)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}
