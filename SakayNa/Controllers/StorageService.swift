import Foundation

// All app data is in Firestore now. This only cleans up the JSON files and
// photos that older versions of the app saved in the Documents folder.
enum StorageService {
    static func removeOldLocalData() {
        let fileManager = FileManager.default
        let folder = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let files = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files where ["json", "jpg"].contains(file.pathExtension.lowercased()) {
            try? fileManager.removeItem(at: file)
        }
    }
}
