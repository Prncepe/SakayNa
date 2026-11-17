import Foundation
import FirebaseFirestore

enum VehicleService {
    private static var vehicles: CollectionReference {
        Firestore.firestore().collection("vehicles")
    }

    static func listen(
        onChange: @escaping ([Vehicle]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        vehicles.addSnapshotListener { snapshot, error in
            if let error {
                onError(error)
                return
            }
            let list = snapshot?.documents.compactMap { document -> Vehicle? in
                guard var vehicle = try? document.data(as: Vehicle.self) else { return nil }
                vehicle.id = document.documentID
                return vehicle
            } ?? []
            onChange(list)
        }
    }

    static func create(_ vehicle: Vehicle) async throws {
        let data = try Firestore.Encoder().encode(vehicle)
        try await vehicles.document(vehicle.id).setData(data)
    }

    // Leaves the rating counters alone so an edit never overwrites new reviews.
    static func update(_ vehicle: Vehicle) async throws {
        var data = try Firestore.Encoder().encode(vehicle)
        data.removeValue(forKey: "ratingSum")
        data.removeValue(forKey: "ratingCount")
        try await vehicles.document(vehicle.id).setData(data, merge: true)
    }

    static func setActive(id: String, isActive: Bool) async throws {
        try await vehicles.document(id).updateData(["isActive": isActive])
    }

    static func delete(_ vehicle: Vehicle) async throws {
        await PhotoService.deleteAll(in: "vehicles/\(vehicle.id)/photos")
        await PhotoService.delete(vehicle.orcrFileName)
        try await vehicles.document(vehicle.id).delete()
    }

    // Known limitation: any signed-in user can change ratingSum/ratingCount
    // (see firestore.rules). A Cloud Function would fix this in the final project.
    static func addReview(vehicleId: String, review: VehicleReview) async throws {
        let db = Firestore.firestore()
        let batch = db.batch()
        let reviewRef = vehicles.document(vehicleId).collection("reviews").document(review.id)
        try batch.setData(from: review, forDocument: reviewRef)
        batch.updateData([
            "ratingSum": FieldValue.increment(Double(review.rating)),
            "ratingCount": FieldValue.increment(Int64(1))
        ], forDocument: vehicles.document(vehicleId))
        try await batch.commit()
    }

    static func listenToReviews(
        vehicleId: String,
        onChange: @escaping ([VehicleReview]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        vehicles.document(vehicleId).collection("reviews")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onError(error)
                    return
                }
                let list = snapshot?.documents.compactMap { document -> VehicleReview? in
                    guard var review = try? document.data(as: VehicleReview.self) else { return nil }
                    review.id = document.documentID
                    return review
                } ?? []
                onChange(list)
            }
    }
}
