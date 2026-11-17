import Foundation
import Combine
import UIKit
import FirebaseFirestore

final class VehicleController: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var favoriteIds: [String] = []
    @Published var searchQuery = ""
    @Published var category: VehicleFilter = .all
    @Published var selectedVehicle: Vehicle?
    @Published var addonEnabled = false
    @Published var days = 1
    @Published var isFavorite = false
    @Published var showFilters = false
    @Published var sortOption: VehicleSort = .recommended
    @Published var filterMaxPriceText = ""
    @Published var maxPrice: Int?
    @Published var focusSearch = false
    @Published var cityFilter: CityFilter = .all

    @Published var isLoading = false
    @Published var isLoadingReviews = false
    @Published var isSaving = false
    @Published var alertMessage: String?

    private var uid: String?
    private var listener: ListenerRegistration?
    private var reviewsListener: ListenerRegistration?
    private var reviewsByVehicle: [String: [VehicleReview]] = [:]

    // MARK: - Listeners

    func start(uid: String) {
        stop()
        self.uid = uid
        isLoading = true
        listener = VehicleService.listen { [weak self] list in
            guard let self else { return }
            vehicles = list.map { vehicle in
                var copy = vehicle
                copy.reviews = self.reviewsByVehicle[vehicle.id] ?? []
                return copy
            }
            if let selected = selectedVehicle, let fresh = vehicles.first(where: { $0.id == selected.id }) {
                selectedVehicle = fresh
            }
            isLoading = false
        } onError: { [weak self] error in
            self?.isLoading = false
            self?.alertMessage = "Couldn't load vehicles. \(error.localizedDescription)"
        }
    }

    func stop() {
        listener?.remove()
        reviewsListener?.remove()
        listener = nil
        reviewsListener = nil
        uid = nil
        vehicles = []
        favoriteIds = []
        reviewsByVehicle = [:]
        selectedVehicle = nil
        isLoading = false
        isLoadingReviews = false
    }

    func setFavorites(_ ids: [String]) {
        favoriteIds = ids
        if let id = selectedVehicle?.id {
            isFavorite = ids.contains(id)
        }
    }

    private func listenToReviews(vehicleId: String) {
        reviewsListener?.remove()
        isLoadingReviews = reviewsByVehicle[vehicleId] == nil
        reviewsListener = VehicleService.listenToReviews(vehicleId: vehicleId) { [weak self] reviews in
            guard let self else { return }
            isLoadingReviews = false
            reviewsByVehicle[vehicleId] = reviews
            if let index = vehicles.firstIndex(where: { $0.id == vehicleId }) {
                vehicles[index].reviews = reviews
            }
            if selectedVehicle?.id == vehicleId {
                selectedVehicle?.reviews = reviews
            }
        } onError: { [weak self] error in
            self?.isLoadingReviews = false
            self?.alertMessage = "Couldn't load reviews. \(error.localizedDescription)"
        }
    }

    // MARK: - Browsing

    var filteredVehicles: [Vehicle] {
        vehicles.filter { vehicle in
            let matchesCategory = category.vehicleType.map { vehicle.type == $0 } ?? true
            let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || vehicle.name.localizedCaseInsensitiveContains(query)
                || vehicle.type.rawValue.localizedCaseInsensitiveContains(query)
                || vehicle.location.localizedCaseInsensitiveContains(query)
                || vehicle.brand.localizedCaseInsensitiveContains(query)
            let matchesPrice = maxPrice.map { vehicle.pricePerDay <= $0 } ?? true
            let matchesCity = cityFilter == .all || vehicle.location == cityFilter.rawValue
            return vehicle.isActive && matchesCategory && matchesSearch && matchesPrice && matchesCity
        }
    }

    var sortedVehicles: [Vehicle] {
        switch sortOption {
        case .recommended:
            return filteredVehicles
        case .priceLow:
            return filteredVehicles.sorted { $0.pricePerDay < $1.pricePerDay }
        case .priceHigh:
            return filteredVehicles.sorted { $0.pricePerDay > $1.pricePerDay }
        case .highestRated:
            return filteredVehicles.sorted { (Double($0.rating) ?? 0) > (Double($1.rating) ?? 0) }
        }
    }

    var featuredVehicle: Vehicle? {
        if sortOption == .recommended,
           let nmax = sortedVehicles.first(where: { $0.name.contains("NMAX") }) {
            return nmax
        }
        return sortedVehicles.first
    }

    var listVehicles: [Vehicle] {
        guard let featured = featuredVehicle else { return sortedVehicles }
        return sortedVehicles.filter { $0.id != featured.id }
    }

    func listedVehicles(ownerId: String) -> [Vehicle] {
        vehicles.filter { $0.ownerId == ownerId }
    }

    func similarVehicles(to vehicle: Vehicle) -> [Vehicle] {
        vehicles.filter { $0.isActive && $0.type == vehicle.type && $0.id != vehicle.id }
    }

    // MARK: - Delete

    func deleteVehicle(id: String) {
        guard let vehicle = vehicle(id: id) else { return }
        vehicles.removeAll { $0.id == id }
        if selectedVehicle?.id == id {
            selectedVehicle = nil
        }
        Task { @MainActor in
            do {
                try await VehicleService.delete(vehicle)
            } catch {
                alertMessage = "Couldn't delete the vehicle. \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    func deleteVehicles(ownedBy ownerId: String) async {
        let owned = vehicles.filter { $0.ownerId == ownerId }
        for vehicle in owned {
            try? await VehicleService.delete(vehicle)
        }
        vehicles.removeAll { $0.ownerId == ownerId }
        if selectedVehicle?.ownerId == ownerId {
            selectedVehicle = nil
        }
    }

    var addonPricePerDay: Int {
        guard addonEnabled, let selectedVehicle else { return 0 }
        return selectedVehicle.addonPricePerDay
    }

    var liveDailyPrice: Int {
        (selectedVehicle?.pricePerDay ?? 0) + addonPricePerDay
    }

    func vehicle(id: String) -> Vehicle? {
        vehicles.first { $0.id == id }
    }

    func select(_ vehicle: Vehicle) {
        selectedVehicle = vehicle
        addonEnabled = false
        days = 1
        isFavorite = favoriteIds.contains(vehicle.id)
        listenToReviews(vehicleId: vehicle.id)
    }

    func toggleAddon() {
        addonEnabled.toggle()
    }

    func incrementDays() {
        days += 1
    }

    func decrementDays() {
        if days > 1 {
            days -= 1
        }
    }

    // MARK: - Favorites

    var savedVehicles: [Vehicle] {
        favoriteIds.compactMap { id in vehicles.first { $0.id == id } }
    }

    func toggleFavorite() {
        guard let id = selectedVehicle?.id else { return }
        toggleFavorite(id: id)
    }

    func toggleFavorite(id: String) {
        guard let uid else { return }
        let makeFavorite = !favoriteIds.contains(id)
        if makeFavorite {
            favoriteIds.append(id)
        } else {
            favoriteIds.removeAll { $0 == id }
        }
        if selectedVehicle?.id == id {
            isFavorite = makeFavorite
        }
        Task { @MainActor in
            do {
                try await UserService.setFavorite(uid: uid, vehicleId: id, isFavorite: makeFavorite)
            } catch {
                alertMessage = "Couldn't update your saved vehicles. \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Reviews

    // The review id is the booking id, so each booking can be reviewed once.
    func addReview(bookingId: String, vehicleId: String, rating: Int, comment: String, renterId: String, renterName: String) {
        let review = VehicleReview(
            id: bookingId,
            renterId: renterId,
            renterName: renterName,
            rating: rating,
            comment: comment,
            date: Date()
        )
        Task { @MainActor in
            do {
                try await VehicleService.addReview(vehicleId: vehicleId, review: review)
            } catch {
                alertMessage = "Couldn't save your review. \(error.localizedDescription)"
            }
        }
    }

    func applyFilters() {
        let trimmed = filterMaxPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        maxPrice = Int(trimmed)
        showFilters = false
    }

    func requestSearchFocus() {
        category = .all
        focusSearch = true
    }

    // MARK: - Add / edit listing

    @Published var isEditingVehicle = false
    @Published var draftVehicleId = ""
    @Published var draftName = ""
    @Published var draftBrand = ""
    @Published var draftPlace = ""
    @Published var draftPrice = ""
    @Published var draftType: VehicleType = .motorcycle
    @Published var draftDescription = ""
    @Published var draftSeats = "2"
    @Published var draftEngine = ""
    @Published var draftPower = ""
    @Published var draftTorque = ""
    @Published var draftFuel = "Gasoline"
    @Published var draftTransmission = "CVT automatic"
    @Published var draftTopSpeed = ""
    @Published var draftFuelTank = ""
    @Published var draftBrakes = ""
    @Published var ownerTermsChecked = false
    @Published var showOwnerTerms = false
    @Published var photoAdded = false
    @Published var draftPhotoFileName: String?
    @Published var draftPhotoFiles: [String] = []
    @Published var draftORCRFileName: String?
    @Published var draftBlockedDates: Set<DateComponents> = []
    @Published var listingAlert: String?

    let fuels = ["Gasoline", "Diesel", "Electric"]
    let transmissions = ["CVT automatic", "6-speed automatic", "Auto", "Manual"]
    let brakeTypes = ["Disc", "Drum"]

    let ownerTerms: [String] = [
        "Owner confirms the vehicle is roadworthy, properly registered, and accurately described (photos, specs, pricing) in the listing.",
        "Owner must respond to booking requests within 24 hours or the request may expire.",
        "Owner is responsible for maintaining valid vehicle insurance and registration (OR/CR) for the duration of any listing.",
        "Payouts are processed to the Owner's registered GCash/Maya/bank account within 3 business days of trip completion.",
        "SakayNa charges a service fee deducted from each completed booking's payout (exact percentage to be defined)."
    ]

    func beginAddVehicle() {
        isEditingVehicle = false
        selectedVehicle = nil
        draftVehicleId = UUID().uuidString
        draftName = ""
        draftBrand = ""
        draftPlace = ""
        draftPrice = ""
        draftType = .motorcycle
        draftDescription = ""
        draftSeats = "2"
        draftEngine = ""
        draftPower = ""
        draftTorque = ""
        draftFuel = "Gasoline"
        draftTransmission = "CVT automatic"
        draftTopSpeed = ""
        draftFuelTank = ""
        draftBrakes = "Disc"
        ownerTermsChecked = false
        photoAdded = false
        draftPhotoFileName = nil
        draftPhotoFiles = []
        draftORCRFileName = nil
        draftBlockedDates = []
        listingAlert = nil
    }

    func beginEditVehicle(_ vehicle: Vehicle) {
        isEditingVehicle = true
        selectedVehicle = vehicle
        draftVehicleId = vehicle.id
        draftName = vehicle.name
        draftBrand = vehicle.brand
        draftPlace = vehicle.location
        draftPrice = String(vehicle.pricePerDay)
        draftType = vehicle.type
        draftDescription = vehicle.description
        draftSeats = String(vehicle.seats)
        draftEngine = vehicle.specs.engine
        draftPower = vehicle.specs.power
        draftTorque = vehicle.specs.torque
        draftFuel = vehicle.specs.fuelType.isEmpty ? "Gasoline" : vehicle.specs.fuelType
        draftTransmission = vehicle.specs.transmission.isEmpty ? "CVT automatic" : vehicle.specs.transmission
        draftTopSpeed = vehicle.specs.topSpeed ?? ""
        draftFuelTank = vehicle.specs.fuelTank
        draftBrakes = vehicle.specs.brakes ?? ""
        ownerTermsChecked = false
        draftPhotoFiles = vehicle.galleryFiles
        draftPhotoFileName = draftPhotoFiles.first
        photoAdded = !draftPhotoFiles.isEmpty || !vehicle.imageName.isEmpty
        draftORCRFileName = vehicle.orcrFileName
        draftBlockedDates = Set(vehicle.blockedDateKeys.compactMap { key in
            guard let date = Vehicle.date(fromKey: key) else { return nil }
            return Calendar.current.dateComponents([.calendar, .era, .year, .month, .day], from: date)
        })
    }

    func toggleActive(id: String) {
        guard let index = vehicles.firstIndex(where: { $0.id == id }) else { return }
        if !vehicles[index].isActive && !vehicles[index].hasRegistration {
            listingAlert = "Upload the vehicle OR/CR before listing it as Active."
            return
        }
        let newValue = !vehicles[index].isActive
        vehicles[index].isActive = newValue
        Task { @MainActor in
            do {
                try await VehicleService.setActive(id: id, isActive: newValue)
            } catch {
                alertMessage = "Couldn't update the listing. \(error.localizedDescription)"
            }
        }
    }

    func savePickedPhoto(_ image: UIImage) {
        guard draftPhotoFiles.count < 5, !draftVehicleId.isEmpty else { return }
        let path = "vehicles/\(draftVehicleId)/photos/\(UUID().uuidString)"
        isSaving = true
        Task { @MainActor in
            do {
                let reference = try await PhotoService.save(image, path: path)
                draftPhotoFiles.append(reference)
                draftPhotoFileName = draftPhotoFiles.first
                photoAdded = true
            } catch {
                alertMessage = "Couldn't upload the photo. \(error.localizedDescription)"
            }
            isSaving = false
        }
    }

    func removeDraftPhoto(at index: Int) {
        guard draftPhotoFiles.indices.contains(index) else { return }
        let reference = draftPhotoFiles.remove(at: index)
        draftPhotoFileName = draftPhotoFiles.first
        photoAdded = !draftPhotoFiles.isEmpty
        let isSavedOnListing = selectedVehicle?.galleryFiles.contains(reference) ?? false
        if !isSavedOnListing {
            Task { await PhotoService.delete(reference) }
        }
    }

    func makeCoverPhoto(at index: Int) {
        guard draftPhotoFiles.indices.contains(index), index != 0 else { return }
        let file = draftPhotoFiles.remove(at: index)
        draftPhotoFiles.insert(file, at: 0)
        draftPhotoFileName = file
    }

    func savePickedORCR(_ image: UIImage) {
        guard let uid, !draftVehicleId.isEmpty else { return }
        let path = "users/\(uid)/private/orcr-\(draftVehicleId)"
        isSaving = true
        Task { @MainActor in
            do {
                draftORCRFileName = try await PhotoService.save(image, path: path)
            } catch {
                alertMessage = "Couldn't upload the OR/CR. \(error.localizedDescription)"
            }
            isSaving = false
        }
    }

    func agreeToOwnerTerms() {
        ownerTermsChecked = true
        showOwnerTerms = false
    }

    @discardableResult
    func saveDraftVehicle(ownerId: String) -> Bool {
        guard ownerTermsChecked, !draftVehicleId.isEmpty else { return false }
        let price = Int(draftPrice) ?? 0
        let seats = Int(draftSeats) ?? (draftType == .car ? 5 : 2)
        let blocked = draftBlockedDates.compactMap { components -> String? in
            guard let date = Calendar.current.date(from: components) else { return nil }
            return Vehicle.dateKey(for: date)
        }.sorted()
        let orcr = draftORCRFileName
        let spec = VehicleSpecs(
            engine: draftEngine,
            power: draftPower,
            torque: draftTorque,
            fuelType: draftFuel,
            transmission: draftTransmission,
            fuelTank: draftFuelTank,
            brakes: draftType == .motorcycle && !draftBrakes.isEmpty ? draftBrakes : nil,
            topSpeed: draftTopSpeed.isEmpty ? nil : draftTopSpeed
        )
        let brand = draftBrand.isEmpty
            ? (draftName.split(separator: " ").first.map(String.init) ?? "SakayNa")
            : draftBrand

        if isEditingVehicle, let selected = selectedVehicle {
            var updated = selected
            updated.name = draftName.isEmpty ? selected.name : draftName
            updated.brand = brand
            updated.type = draftType
            updated.customImageFile = nil
            updated.description = draftDescription.isEmpty ? selected.description : draftDescription
            updated.pricePerDay = price == 0 ? selected.pricePerDay : price
            updated.location = draftPlace.isEmpty ? selected.location : draftPlace
            updated.seats = seats
            updated.specs = spec
            updated.blockedDateKeys = blocked
            updated.orcrFileName = orcr ?? selected.orcrFileName
            updated.photoFiles = draftPhotoFiles
            let removedPhotos = selected.galleryFiles.filter { !draftPhotoFiles.contains($0) }
            if let index = vehicles.firstIndex(where: { $0.id == selected.id }) {
                vehicles[index] = updated
            }
            let added = blocked.filter { !selected.blockedDateKeys.contains($0) }
            let removed = selected.blockedDateKeys.filter { !blocked.contains($0) }
            write { try await VehicleService.update(updated) }
            syncBlockedDays(vehicleId: updated.id, ownerId: updated.ownerId, added: added, removed: removed)
            Task {
                for reference in removedPhotos {
                    await PhotoService.delete(reference)
                }
            }
        } else {
            let hasORCR = orcr != nil && !(orcr ?? "").isEmpty
            let vehicle = Vehicle(
                id: draftVehicleId,
                ownerId: ownerId,
                name: draftName.isEmpty ? "New \(draftType.rawValue)" : draftName,
                brand: brand,
                type: draftType,
                imageName: "",
                description: draftDescription,
                pricePerDay: max(price, 0),
                location: draftPlace.isEmpty ? "Lucena" : draftPlace,
                seats: seats,
                rating: "0.0",
                reviewCount: 0,
                specs: spec,
                isActive: hasORCR,
                blockedDateKeys: blocked,
                orcrFileName: orcr,
                photoFiles: draftPhotoFiles
            )
            vehicles.append(vehicle)
            Task { @MainActor in
                do {
                    try await VehicleService.create(vehicle)
                } catch {
                    alertMessage = "Couldn't save the vehicle. \(error.localizedDescription)"
                    return
                }
                syncBlockedDays(vehicleId: vehicle.id, ownerId: ownerId, added: blocked, removed: [])
            }
        }
        return true
    }

    // Blocked dates also go in vehicles/{id}/bookedDays (type "blocked") so the
    // booking transaction treats them like booked days.
    private func syncBlockedDays(vehicleId: String, ownerId: String, added: [String], removed: [String]) {
        guard !added.isEmpty || !removed.isEmpty else { return }
        Task { @MainActor in
            do {
                let skipped = try await BookingService.updateBlockedDays(
                    vehicleId: vehicleId, ownerId: ownerId, added: added, removed: removed
                )
                if !skipped.isEmpty {
                    let dates = skipped.compactMap { Vehicle.date(fromKey: $0) }.map { AppFormat.shortDate($0) }
                    alertMessage = "These dates already have a booking and weren't blocked: \(dates.joined(separator: ", "))."
                }
            } catch {
                alertMessage = "Couldn't update blocked dates. \(error.localizedDescription)"
            }
        }
    }

    private func write(_ operation: @escaping () async throws -> Void) {
        Task { @MainActor in
            do {
                try await operation()
            } catch {
                alertMessage = "Couldn't save the vehicle. \(error.localizedDescription)"
            }
        }
    }
}
