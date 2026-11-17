import SwiftUI

struct VehicleGalleryView: View {
    @Environment(\.palette) private var palette
    let vehicle: Vehicle
    var height: CGFloat = 170

    var body: some View {
        let files = vehicle.galleryFiles
        Group {
            if files.count > 1 {
                TabView {
                    ForEach(files, id: \.self) { file in
                        VehicleImageView(imageName: "", customImageFile: file, height: height)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            } else if let file = files.first {
                VehicleImageView(imageName: vehicle.imageName, customImageFile: file, height: height)
            } else {
                VehicleImageView(vehicle: vehicle, height: height)
            }
        }
        .frame(height: height)
    }
}
