import Foundation
import FirebaseFirestore

enum UserService {
    private static var users: CollectionReference {
        Firestore.firestore().collection("users")
    }

    static func fetch(uid: String) async throws -> User? {
        let snapshot = try await users.document(uid).getDocument()
        return decode(snapshot)
    }

    static func save(_ user: User) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await users.document(user.id).setData(data, merge: true)
    }

    static func setFavorite(uid: String, vehicleId: String, isFavorite: Bool) async throws {
        let change = isFavorite ? FieldValue.arrayUnion([vehicleId]) : FieldValue.arrayRemove([vehicleId])
        try await users.document(uid).updateData(["favorites": change])
    }

    static func delete(uid: String) async throws {
        try await users.document(uid).delete()
    }

    static func listenToUser(
        uid: String,
        onChange: @escaping (User?) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        users.document(uid).addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }
            onChange(snapshot.flatMap(decode))
        }
    }

    static func listenToAllUsers(
        onChange: @escaping ([User]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        users.addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }
            let list = snapshot?.documents.compactMap { decode($0) } ?? []
            onChange(list)
        }
    }

    private static func decode(_ snapshot: DocumentSnapshot) -> User? {
        guard snapshot.exists, var user = try? snapshot.data(as: User.self) else { return nil }
        user.id = snapshot.documentID
        return user
    }
}
