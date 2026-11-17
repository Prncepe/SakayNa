import Foundation
import FirebaseFirestore

// The in-app notification list lives in users/{uid}/notifications.
// Each phone listens to its own list and shows the island drop (and a phone
// banner via LocalNotificationService) only while the app is running.
// Real push notifications when the app is closed need APNs plus Cloud Functions
// that send a push whenever a notification document is created. That is left
// for the final project.
enum NotificationService {
    private static func notifications(of uid: String) -> CollectionReference {
        Firestore.firestore().collection("users").document(uid).collection("notifications")
    }

    static func listen(
        uid: String,
        onChange: @escaping (_ all: [AppNotification], _ added: [AppNotification]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        notifications(of: uid)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onError(error)
                    return
                }
                guard let snapshot else { return }
                let all = snapshot.documents.compactMap(decode)
                let added = snapshot.documentChanges
                    .filter { $0.type == .added }
                    .compactMap { decode($0.document) }
                onChange(all, added)
            }
    }

    static func send(_ notification: AppNotification, to uid: String) async throws {
        let data = try Firestore.Encoder().encode(notification)
        try await notifications(of: uid).document(notification.id).setData(data)
    }

    static func markRead(uid: String, notificationId: String) async throws {
        try await notifications(of: uid).document(notificationId).updateData(["isRead": true])
    }

    static func deleteAll(uid: String) async {
        guard let snapshot = try? await notifications(of: uid).getDocuments() else { return }
        for document in snapshot.documents {
            try? await document.reference.delete()
        }
    }

    private static func decode(_ document: QueryDocumentSnapshot) -> AppNotification? {
        guard var item = try? document.data(as: AppNotification.self) else { return nil }
        item.id = document.documentID
        return item
    }
}
