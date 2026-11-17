import UIKit
import FirebaseFirestore

enum PhotoServiceError: LocalizedError {
    case tooLarge

    var errorDescription: String? {
        "This photo is too large to upload. Try a different photo."
    }
}

// Photos are stored as Firestore documents ({ data, ownerId, createdAt }) because
// Firebase Storage needs the Blaze plan. A photo "reference" is the document path,
// e.g. "vehicles/veh-click/photos/<uuid>". To move to Firebase Storage later,
// only this file needs to change.
enum PhotoService {
    private static let cache = NSCache<NSString, UIImage>()
    private static let maxSide: CGFloat = 1000
    private static let maxBytes = 700_000

    static func isReference(_ value: String) -> Bool {
        value.contains("/")
    }

    @discardableResult
    static func save(_ image: UIImage, path: String) async throws -> String {
        guard let data = compressedJPEG(image) else { throw PhotoServiceError.tooLarge }
        try await Firestore.firestore().document(path).setData([
            "data": data,
            "ownerId": AuthService.currentUID ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ])
        if let stored = UIImage(data: data) {
            cache.setObject(stored, forKey: path as NSString)
        }
        return path
    }

    static func cachedImage(_ reference: String) -> UIImage? {
        cache.object(forKey: reference as NSString)
    }

    static func load(_ reference: String) async throws -> UIImage? {
        if let cached = cachedImage(reference) { return cached }
        let snapshot = try await Firestore.firestore().document(reference).getDocument()
        guard let data = snapshot.get("data") as? Data, let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: reference as NSString)
        return image
    }

    static func delete(_ reference: String?) async {
        guard let reference, isReference(reference) else { return }
        cache.removeObject(forKey: reference as NSString)
        try? await Firestore.firestore().document(reference).delete()
    }

    static func deleteAll(in collectionPath: String) async {
        guard let snapshot = try? await Firestore.firestore().collection(collectionPath).getDocuments() else { return }
        for document in snapshot.documents {
            cache.removeObject(forKey: document.reference.path as NSString)
            try? await document.reference.delete()
        }
    }

    private static func compressedJPEG(_ image: UIImage) -> Data? {
        let resized = resized(image)
        var quality: CGFloat = 0.8
        while quality >= 0.2 {
            if let data = resized.jpegData(compressionQuality: quality), data.count <= maxBytes {
                return data
            }
            quality -= 0.1
        }
        return nil
    }

    private static func resized(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxSide, longest > 0 else { return image }
        let scale = maxSide / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
