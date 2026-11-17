import SwiftUI

struct ProfileView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var messages: MessageController
    @Binding var path: NavigationPath
    @State private var showDeleteAccount = false
    @State private var deleteBlockMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader()

                AppCard {
                    HStack(spacing: 16) {
                        Text(auth.user.initial)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Color(hexString: auth.user.avatarColorHex))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.user.name)
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundStyle(palette.text)
                            Text("\(auth.user.email) · \(auth.user.phone)")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                            if auth.user.role == .owner {
                                let summary = bookings.ownerRatingSummary(ownerId: auth.user.id)
                                HStack(spacing: 6) {
                                    Text("JD Motors")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(palette.yellow)
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                        Text(summary.count == 0 ? summary.text : "\(summary.text) (\(summary.count))")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(palette.yellow)
                                }
                            }
                        }
                    }
                }

                AppCard {
                    VStack(spacing: 16) {
                        Button(action: auth.toggleTheme) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dark Mode")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(palette.text)
                                    Text("App appearance")
                                        .font(.system(size: 12))
                                        .foregroundStyle(palette.muted)
                                }
                                Spacer()
                                AppToggle(isOn: auth.theme == .dark, action: auth.toggleTheme)
                            }
                        }
                        .buttonStyle(.plain)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(palette.text)
                                Text("Approvals, messages, and trip updates")
                                    .font(.system(size: 12))
                                    .foregroundStyle(palette.muted)
                            }
                            Spacer()
                            AppToggle(isOn: auth.notificationsEnabled) {
                                auth.toggleNotifications()
                                bookings.syncScheduledReminders()
                            }
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Language")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(palette.text)
                                Text("English")
                                    .font(.system(size: 12))
                                    .foregroundStyle(palette.muted)
                            }
                            Spacer()
                        }

                        settingsButton(title: "Edit Profile", systemName: "gearshape") {
                            auth.beginEditProfile()
                            path.append(AppRoute.editProfile)
                        }
                        settingsButton(
                            title: auth.user.role == .owner ? "Payout Methods" : "Payment Methods",
                            systemName: "creditcard"
                        ) {
                            auth.beginPaymentMethods()
                            path.append(AppRoute.paymentMethods)
                        }
                        if auth.user.role == .owner {
                            settingsButton(
                                title: auth.user.isVerifiedOwner ? "Verified account" : "Verify my account",
                                systemName: "checkmark.seal"
                            ) {
                                path.append(AppRoute.verifyAccount)
                            }
                        }
                        if auth.user.role == .renter {
                            settingsButton(title: "Saved Vehicles", systemName: "heart") {
                                path.append(AppRoute.savedVehicles)
                            }
                            settingsButton(title: "ID / License", systemName: "person.text.rectangle") {
                                path.append(AppRoute.licenseUpload)
                            }
                            settingsButton(title: "Notifications", systemName: "bell") {
                                path.append(AppRoute.notificationSettings)
                            }
                        }
                        settingsButton(title: "Help & Support", systemName: "heart") {
                            path.append(AppRoute.helpSupport)
                        }
                        settingsButton(title: "Terms & Conditions", systemName: "doc.text") {
                            path.append(AppRoute.termsAndConditions)
                        }
                        settingsButton(title: "Privacy Policy", systemName: "hand.raised") {
                            path.append(AppRoute.privacyPolicy)
                        }
                        settingsButton(title: "About", systemName: "info.circle") {
                            path.append(AppRoute.about)
                        }
                    }
                }

                OutlineButton(title: "Log Out") {
                    bookings.resetToHome()
                    auth.logout()
                }

                Button("Delete my account") {
                    auth.deleteConfirmText = ""
                    showDeleteAccount = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.danger)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(24)
            .padding(.bottom, 88)
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert("Delete my account?", isPresented: $showDeleteAccount) {
            TextField("Type DELETE", text: $auth.deleteConfirmText)
            Button("Delete", role: .destructive, action: confirmDeleteAccount)
            Button("Cancel", role: .cancel) {
                auth.deleteConfirmText = ""
            }
        } message: {
            Text("This removes your profile, photos, vehicles, favorites, and chats. Type DELETE to confirm.")
        }
        .alert("Confirm your password", isPresented: $auth.showReauthPrompt) {
            SecureField("Password", text: $auth.reauthPassword)
            Button("Delete", role: .destructive, action: auth.confirmReauthAndDelete)
            Button("Cancel", role: .cancel) {
                auth.reauthPassword = ""
            }
        } message: {
            Text("For your security, enter your password again to delete your account.")
        }
        .alert("Can't delete account", isPresented: Binding(
            get: { deleteBlockMessage != nil },
            set: { if !$0 { deleteBlockMessage = nil } }
        )) {
            Button("OK", role: .cancel) { deleteBlockMessage = nil }
        } message: {
            Text(deleteBlockMessage ?? "")
        }
    }

    private func confirmDeleteAccount() {
        guard auth.deleteConfirmText == "DELETE" else { return }
        if let reason = bookings.reasonIfAccountDeleteBlocked(userId: auth.user.id) {
            deleteBlockMessage = reason
            return
        }
        let userId = auth.user.id
        auth.deleteAccount {
            await vehicles.deleteVehicles(ownedBy: userId)
            await messages.deleteConversations(involving: userId)
            await NotificationService.deleteAll(uid: userId)
            await bookings.anonymizeDeletedUser(userId)
            bookings.resetToHome()
        }
    }

    private func settingsButton(title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemName)
                    .font(.system(size: 16))
                    .foregroundStyle(palette.muted)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.muted)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
