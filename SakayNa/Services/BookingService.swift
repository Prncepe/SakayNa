import Foundation
import CryptoKit
import FirebaseFirestore

// Day documents live in vehicles/{vehicleId}/bookedDays/{yyyy-MM-dd}.
// A day is taken if its document exists (type "booking" or "blocked").
// Creating one is done in a transaction, so two phones can't book the same day.
enum BookingService {
    static let notAvailableMessage = "This vehicle is already booked for those dates. Please pick different dates."

    private static var db: Firestore { Firestore.firestore() }
    private static var bookings: CollectionReference { db.collection("bookings") }

    private static func dayRef(vehicleId: String, key: String) -> DocumentReference {
        db.collection("vehicles").document(vehicleId).collection("bookedDays").document(key)
    }

    private static func notAvailableError() -> NSError {
        NSError(domain: "SakayNa", code: 409, userInfo: [NSLocalizedDescriptionKey: notAvailableMessage])
    }

    private static func dayData(vehicleId: String, key: String, bookingId: String, type: String, ownerId: String, renterId: String) -> [String: Any] {
        [
            "bookingId": bookingId,
            "type": type,
            "date": Timestamp(date: Vehicle.date(fromKey: key) ?? Date()),
            "vehicleId": vehicleId,
            "ownerId": ownerId,
            "renterId": renterId
        ]
    }

    // MARK: - Listening

    // field is "renterId" or "ownerId"; the controller merges both lists.
    static func listen(
        field: String,
        uid: String,
        onChange: @escaping ([Booking]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        bookings.whereField(field, isEqualTo: uid).addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }
            let list = snapshot?.documents.compactMap { document -> Booking? in
                guard var booking = try? document.data(as: Booking.self) else { return nil }
                booking.id = document.documentID
                return booking
            } ?? []
            onChange(list)
        }
    }

    // MARK: - Create with no double booking

    static func create(_ booking: Booking, dayKeys: [String]) async throws {
        let bookingData = try Firestore.Encoder().encode(booking)
        let bookingRef = bookings.document(booking.id)
        let vehicleId = booking.vehicle.id
        let dayRefs = dayKeys.map { dayRef(vehicleId: vehicleId, key: $0) }

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                for ref in dayRefs {
                    if try transaction.getDocument(ref).exists {
                        errorPointer?.pointee = notAvailableError()
                        return nil
                    }
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            transaction.setData(bookingData, forDocument: bookingRef)
            for (ref, key) in zip(dayRefs, dayKeys) {
                transaction.setData(
                    dayData(vehicleId: vehicleId, key: key, bookingId: booking.id, type: "booking",
                            ownerId: booking.ownerId, renterId: booking.renterId ?? ""),
                    forDocument: ref
                )
            }
            return nil
        }
    }

    // Extension approval: reserves the extra days and updates the booking together.
    static func reserveExtraDays(_ booking: Booking, dayKeys: [String], fields: [String]) async throws {
        let updates = try changes(of: booking, fields: fields)
        let bookingRef = bookings.document(booking.id)
        let vehicleId = booking.vehicle.id
        let dayRefs = dayKeys.map { dayRef(vehicleId: vehicleId, key: $0) }

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                for ref in dayRefs {
                    let snapshot = try transaction.getDocument(ref)
                    if snapshot.exists, snapshot.get("bookingId") as? String != booking.id {
                        errorPointer?.pointee = notAvailableError()
                        return nil
                    }
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            transaction.updateData(updates, forDocument: bookingRef)
            for (ref, key) in zip(dayRefs, dayKeys) {
                transaction.setData(
                    dayData(vehicleId: vehicleId, key: key, bookingId: booking.id, type: "booking",
                            ownerId: booking.ownerId, renterId: booking.renterId ?? ""),
                    forDocument: ref
                )
            }
            return nil
        }
    }

    static func areDaysFree(vehicleId: String, dayKeys: [String]) async throws -> Bool {
        for key in dayKeys {
            let snapshot = try await dayRef(vehicleId: vehicleId, key: key).getDocument()
            if snapshot.exists { return false }
        }
        return true
    }

    // Called when a booking becomes Declined, Cancelled, or Completed.
    static func releaseDays(vehicleId: String, bookingId: String) async {
        let query = db.collection("vehicles").document(vehicleId).collection("bookedDays")
            .whereField("bookingId", isEqualTo: bookingId)
        guard let snapshot = try? await query.getDocuments() else { return }
        for document in snapshot.documents {
            try? await document.reference.delete()
        }
    }

    // MARK: - Updates

    // Writes only the listed fields. A field that is nil in Swift is deleted.
    static func update(_ booking: Booking, fields: [String]) async throws {
        let updates = try changes(of: booking, fields: fields)
        try await bookings.document(booking.id).updateData(updates)
    }

    private static func changes(of booking: Booking, fields: [String]) throws -> [String: Any] {
        let encoded = try Firestore.Encoder().encode(booking)
        var updates: [String: Any] = [:]
        for field in fields {
            updates[field] = encoded[field] ?? FieldValue.delete()
        }
        return updates
    }

    // MARK: - Pickup PIN

    static func hashPIN(_ pin: String, bookingId: String) -> String {
        let digest = SHA256.hash(data: Data("\(bookingId):\(pin)".utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func savePIN(_ pin: String, bookingId: String) async throws {
        try await bookings.document(bookingId).collection("private").document("pin").setData(["pin": pin])
    }

    static func loadPIN(bookingId: String) async -> String? {
        let snapshot = try? await bookings.document(bookingId).collection("private").document("pin").getDocument()
        return snapshot?.get("pin") as? String
    }

    // MARK: - Availability ("Available on my dates")

    // Collection group query across every vehicle's bookedDays. The first time it
    // runs, Firebase may print a link in the Xcode console to create the index.
    static func unavailableVehicleIds(from start: Date, to end: Date) async throws -> Set<String> {
        let snapshot = try await db.collectionGroup("bookedDays")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: Calendar.current.startOfDay(for: start)))
            .whereField("date", isLessThan: Timestamp(date: Calendar.current.startOfDay(for: end)))
            .getDocuments()
        return Set(snapshot.documents.compactMap { $0.get("vehicleId") as? String })
    }

    // MARK: - Owner blocked dates

    static func updateBlockedDays(vehicleId: String, ownerId: String, added: [String], removed: [String]) async throws -> [String] {
        var skipped: [String] = []
        for key in added {
            let ref = dayRef(vehicleId: vehicleId, key: key)
            if try await ref.getDocument().exists {
                skipped.append(key)
                continue
            }
            try await ref.setData(dayData(vehicleId: vehicleId, key: key, bookingId: "", type: "blocked",
                                          ownerId: ownerId, renterId: ""))
        }
        for key in removed {
            let ref = dayRef(vehicleId: vehicleId, key: key)
            let snapshot = try await ref.getDocument()
            if snapshot.get("type") as? String == "blocked" {
                try await ref.delete()
            }
        }
        return skipped
    }

    // MARK: - Ratings

    // Known limitation: any signed-in user can change these counters (see rules).
    static func addUserRating(uid: String, stars: Int) async throws {
        try await db.collection("users").document(uid).updateData([
            "ratingSum": FieldValue.increment(Int64(stars)),
            "ratingCount": FieldValue.increment(Int64(1))
        ])
    }
}
