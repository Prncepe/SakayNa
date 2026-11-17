import SwiftUI
import PhotosUI
import UIKit

struct AddVehicleView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController
    @Binding var path: NavigationPath
    @State private var pickedORCR: PhotosPickerItem?
    @State private var showDeleteConfirm = false
    @State private var deleteBlockMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader(
                    title: vehicles.isEditingVehicle ? "Edit Vehicle" : "Add Vehicle",
                    showsBack: true,
                    showsProfileActions: false
                ) {
                    if !path.isEmpty { path.removeLast() }
                }

                AppCard {
                    VStack(spacing: 16) {
                        VehiclePhotoPicker()
                        typePicker
                        PillField(label: "VEHICLE NAME / MODEL", placeholder: "e.g. Yamaha NMAX", text: $vehicles.draftName)
                        PillField(label: "BRAND", placeholder: "e.g. Yamaha", text: $vehicles.draftBrand)
                        PillField(label: "LOCATION", placeholder: "e.g. Manila", text: $vehicles.draftPlace)
                        PillField(label: "PRICE PER DAY", placeholder: "700", keyboard: .numberPad, text: $vehicles.draftPrice)
                        specFields
                        orcrPicker
                        blockedDatesPicker
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    Button {
                        vehicles.ownerTermsChecked.toggle()
                    } label: {
                        Image(systemName: vehicles.ownerTermsChecked ? "checkmark.square.fill" : "square")
                            .foregroundStyle(vehicles.ownerTermsChecked ? palette.yellow : palette.muted)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I agree to the")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                        Button("Owner Terms & Conditions") {
                            vehicles.showOwnerTerms = true
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .underline()
                        .foregroundStyle(palette.text)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.text.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )

                PrimaryButton(title: "Save Vehicle", isEnabled: vehicles.ownerTermsChecked) {
                    if vehicles.saveDraftVehicle(ownerId: auth.user.id), !path.isEmpty {
                        path.removeLast()
                    }
                }

                if vehicles.isEditingVehicle {
                    Button("Delete Vehicle") {
                        let id = vehicles.selectedVehicle?.id ?? ""
                        if let reason = bookings.reasonIfDeleteBlocked(vehicleId: id) {
                            deleteBlockMessage = reason
                        } else {
                            showDeleteConfirm = true
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
            }
            .padding(24)
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $vehicles.showOwnerTerms) {
            ownerTermsSheet
        }
        .alert("Can't delete vehicle", isPresented: Binding(
            get: { deleteBlockMessage != nil },
            set: { if !$0 { deleteBlockMessage = nil } }
        )) {
            Button("OK", role: .cancel) { deleteBlockMessage = nil }
        } message: {
            Text(deleteBlockMessage ?? "")
        }
        .alert("Delete this vehicle?", isPresented: $showDeleteConfirm) {
            Button("Keep Vehicle", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let id = vehicles.selectedVehicle?.id {
                    vehicles.deleteVehicle(id: id)
                    if !path.isEmpty { path.removeLast() }
                }
            }
        } message: {
            Text("This listing will be removed from SakayNa.")
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VEHICLE TYPE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(palette.muted)
            HStack(spacing: 8) {
                FilterChip(title: "🏍 Motorcycle", isActive: vehicles.draftType == .motorcycle, fillsWidth: true) {
                    vehicles.draftType = .motorcycle
                }
                FilterChip(title: "🚗 Car", isActive: vehicles.draftType == .car, fillsWidth: true) {
                    vehicles.draftType = .car
                }
            }
        }
    }

    private var specFields: some View {
        VStack(spacing: 16) {
            PillField(label: "DESCRIPTION", placeholder: "Short description for renters", text: $vehicles.draftDescription)
            PillField(label: "SEATS / RIDERS", placeholder: vehicles.draftType == .car ? "5" : "2", keyboard: .numberPad, text: $vehicles.draftSeats)
            PillField(label: "ENGINE", placeholder: "e.g. 155 cc, liquid-cooled", text: $vehicles.draftEngine)
            PillField(label: "POWER", placeholder: "e.g. 15.1 hp", text: $vehicles.draftPower)
            PillField(label: "TORQUE", placeholder: "e.g. 13.9 Nm", text: $vehicles.draftTorque)
            pickerField("FUEL TYPE", selection: $vehicles.draftFuel, options: vehicles.fuels)
            pickerField("TRANSMISSION", selection: $vehicles.draftTransmission, options: vehicles.transmissions)
            PillField(label: "FUEL TANK", placeholder: "e.g. 7.1 L", text: $vehicles.draftFuelTank)
            PillField(label: "TOP SPEED (optional)", placeholder: "Leave empty if unknown", text: $vehicles.draftTopSpeed)
            if vehicles.draftType == .motorcycle {
                pickerField("BRAKES", selection: $vehicles.draftBrakes, options: vehicles.brakeTypes)
            }
        }
    }

    private var orcrPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OR / CR")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(palette.muted)
            PhotosPicker(selection: $pickedORCR, matching: .images) {
                HStack {
                    Image(systemName: vehicles.draftORCRFileName == nil ? "doc.badge.plus" : "checkmark.circle.fill")
                        .foregroundStyle(vehicles.draftORCRFileName == nil ? palette.muted : palette.yellow)
                    Text(vehicles.draftORCRFileName == nil ? "Upload registration (OR/CR)" : "OR/CR uploaded")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.text)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .frame(height: 54)
                .background(palette.fieldFill)
                .overlay(Capsule().stroke(palette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .onChange(of: pickedORCR) { _, item in
                Task { await loadORCR(item) }
            }
            Text("A vehicle can't be listed as Active without OR/CR.")
                .font(.system(size: 12))
                .foregroundStyle(palette.muted)
        }
    }

    private var blockedDatesPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BLOCKED DATES")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(palette.muted)
            MultiDatePicker(
                "Unavailable dates",
                selection: $vehicles.draftBlockedDates,
                in: Date.now...
            )
            .tint(palette.yellow)
            Text("Renters can't book these dates (maintenance or personal use).")
                .font(.system(size: 12))
                .foregroundStyle(palette.muted)
        }
    }

    private func loadORCR(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            vehicles.savePickedORCR(image)
        }
    }

    private func pickerField(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(palette.muted)
                .padding(.leading, 8)
            HStack {
                Picker(label, selection: selection) {
                    ForEach(options, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(palette.text)
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(palette.fieldFill)
            .overlay(Capsule().stroke(palette.border, lineWidth: 1))
            .clipShape(Capsule())
        }
    }

    private var ownerTermsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(vehicles.ownerTerms, id: \.self) { term in
                        Text(term)
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                            .padding(.leading, 12)
                            .overlay(alignment: .leading) {
                                Rectangle().fill(palette.yellow).frame(width: 2)
                            }
                    }
                }
                .padding(24)
            }
            .background(palette.canvas)
            .navigationTitle("Owner Terms & Conditions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { vehicles.showOwnerTerms = false }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "I Agree", action: vehicles.agreeToOwnerTerms)
                    .padding(24)
            }
        }
    }
}
