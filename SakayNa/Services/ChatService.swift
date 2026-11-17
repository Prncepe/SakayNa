import Foundation
import FirebaseFirestore

enum ChatService {
    private static var db: Firestore { Firestore.firestore() }
    private static var conversations: CollectionReference { db.collection("conversations") }

    static func listenToInbox(
        uid: String,
        onChange: @escaping ([Conversation]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        conversations.whereField("participantIds", arrayContains: uid).addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }
            let list = snapshot?.documents.compactMap { document -> Conversation? in
                guard var conversation = try? document.data(as: Conversation.self) else { return nil }
                conversation.id = document.documentID
                return conversation
            } ?? []
            onChange(list)
        }
    }

    static func listenToMessages(
        conversationId: String,
        onChange: @escaping ([Message]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        conversations.document(conversationId).collection("messages")
            .order(by: "date")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onError(error)
                    return
                }
                let list = snapshot?.documents.compactMap { document -> Message? in
                    guard var message = try? document.data(as: Message.self) else { return nil }
                    message.id = document.documentID
                    return message
                } ?? []
                onChange(list)
            }
    }

    // Creates the conversation if it's new, or attaches the booking id if missing.
    static func createIfNeeded(_ conversation: Conversation) async throws {
        let ref = conversations.document(conversation.id)
        let data = try Firestore.Encoder().encode(conversation)
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(ref)
                if !snapshot.exists {
                    transaction.setData(data, forDocument: ref)
                } else if let bookingId = conversation.bookingId, snapshot.get("bookingId") == nil {
                    transaction.updateData(["bookingId": bookingId], forDocument: ref)
                }
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    // Adds the message and updates the inbox fields in one batch. The merge also
    // creates the conversation if this is the first message.
    static func send(_ message: Message, in conversation: Conversation) async throws {
        let ref = conversations.document(conversation.id)
        let otherId = conversation.otherUserId(than: message.senderId)
        let batch = db.batch()
        var conversationData: [String: Any] = [
            "participantIds": [conversation.renterId, conversation.ownerId],
            "renterId": conversation.renterId,
            "ownerId": conversation.ownerId,
            "vehicleId": conversation.vehicleId,
            "lastMessage": message.text,
            "lastSenderId": message.senderId,
            "lastUpdated": Timestamp(date: message.date),
            "unread": [otherId: FieldValue.increment(Int64(1))]
        ]
        if let bookingId = conversation.bookingId {
            conversationData["bookingId"] = bookingId
        }
        batch.setData(conversationData, forDocument: ref, merge: true)
        try batch.setData(from: message, forDocument: ref.collection("messages").document(message.id))
        try await batch.commit()
    }

    static func markRead(conversationId: String, uid: String) async throws {
        try await conversations.document(conversationId).updateData(["unread.\(uid)": 0])
    }

    static func setBlocked(conversationId: String, uid: String, isBlocked: Bool) async throws {
        let change = isBlocked ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid])
        try await conversations.document(conversationId).updateData(["blockedBy": change])
    }

    static func report(reporterId: String, reportedId: String, reason: String, conversationId: String) async throws {
        try await db.collection("reports").addDocument(data: [
            "reporterId": reporterId,
            "reportedId": reportedId,
            "reason": reason,
            "conversationId": conversationId,
            "date": Timestamp(date: Date())
        ])
    }

    static func delete(conversationId: String) async {
        let ref = conversations.document(conversationId)
        if let snapshot = try? await ref.collection("messages").getDocuments() {
            for document in snapshot.documents {
                try? await document.reference.delete()
            }
        }
        try? await ref.delete()
    }
}
