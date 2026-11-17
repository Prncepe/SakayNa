import Foundation
import Combine
import UIKit
import FirebaseFirestore

final class AuthController: ObservableObject {
    @Published var isLoggedIn = false
    @Published var authScreen: AuthScreen = .splash
    @Published var theme: AppTheme = .light
    @Published var currentUser: User?
    @Published var users: [User] = []
    @Published var keepSignedIn = true

    @Published var isRestoringSession = false
    @Published var isBusy = false
    @Published var alertTitle = ""
    @Published var alertMessage: String?

    @Published var loginPhone = ""
    @Published var loginPassword = ""
    @Published var loginPhoneError: String?
    @Published var loginPasswordError: String?
    @Published var showPassword = false

    @Published var regName = ""
    @Published var regEmail = ""
    @Published var regPhone = ""
    @Published var regPassword = ""
    @Published var regNameError: String?
    @Published var regEmailError: String?
    @Published var regPhoneError: String?
    @Published var regPasswordError: String?
    @Published var selectedRole: UserRole = .renter
    @Published var signupTermsAccepted = false
    @Published var signupTermsError: String?
    @Published var deleteConfirmText = ""
    @Published var showReauthPrompt = false
    @Published var reauthPassword = ""
    @Published var licenseUploaded = false

    @Published var editName = ""
    @Published var editEmail = ""
    @Published var editPhone = ""
    @Published var showAvatarColors = false

    @Published var gcashDraft = ""
    @Published var mayaDraft = ""
    @Published var bankDraft = ""
    @Published var qrPhDraft = false
    @Published var qrUploaded = false
    @Published var notificationsEnabled = true

    private var userListener: ListenerRegistration?
    private var allUsersListener: ListenerRegistration?
    private var pendingDeleteCleanup: (@MainActor () async -> Void)?

    private enum PrefKey {
        static let keepSignedIn = "pref.keepSignedIn"
        static let theme = "pref.theme"
        static let notifications = "pref.notificationsEnabled"
    }

    var user: User {
        currentUser ?? .empty
    }

    func user(id: String) -> User? {
        users.first { $0.id == id }
    }

    var hasLicense: Bool {
        if let name = user.licenseFileName, !name.isEmpty { return true }
        return false
    }

    var hasQR: Bool {
        if let name = user.qrFileName, !name.isEmpty { return true }
        return false
    }

    init() {
        let defaults = UserDefaults.standard
        keepSignedIn = defaults.object(forKey: PrefKey.keepSignedIn) as? Bool ?? true
        theme = AppTheme(rawValue: defaults.string(forKey: PrefKey.theme) ?? "") ?? .light
        notificationsEnabled = defaults.object(forKey: PrefKey.notifications) as? Bool ?? true

        guard let uid = AuthService.currentUID else { return }
        if keepSignedIn {
            isRestoringSession = true
            startSession(uid: uid)
        } else {
            AuthService.signOut()
        }
    }

    func goToLogin() {
        authScreen = .login
    }

    func goToSignup() {
        authScreen = .signup
    }

    // MARK: - Login

    func login() {
        loginPhoneError = nil
        loginPasswordError = nil

        let phone = loginPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = loginPassword
        var isValid = true

        if phone.isEmpty {
            loginPhoneError = "Phone number is required."
            isValid = false
        } else if AuthController.normalizedPhone(phone) == nil {
            loginPhoneError = "Use a PH number: 09XXXXXXXXX or +639XXXXXXXXX."
            isValid = false
        }

        if password.isEmpty {
            loginPasswordError = "Password is required."
            isValid = false
        }

        guard isValid, let normalized = AuthController.normalizedPhone(phone) else { return }

        isBusy = true
        Task { @MainActor in
            do {
                let uid = try await AuthService.signIn(phone: normalized, password: password)
                guard try await UserService.fetch(uid: uid) != nil else {
                    AuthService.signOut()
                    isBusy = false
                    showAlert("Profile not found", "This account has no profile. Please sign up again.")
                    return
                }
                startSession(uid: uid)
            } catch {
                isBusy = false
                let mapped = AuthService.map(error)
                if case .wrongCredentials = mapped {
                    loginPasswordError = mapped.localizedDescription
                } else {
                    showAlert("Can't log in", mapped.localizedDescription)
                }
            }
        }
    }

    func loginWithGoogle() {
        showComingSoon("Google sign-in")
    }

    func loginWithApple() {
        showComingSoon("Sign in with Apple")
    }

    func toggleKeepSignedIn() {
        keepSignedIn.toggle()
        savePrefs()
    }

    // MARK: - Sign up

    func signUp() {
        signupTermsError = nil
        guard signupTermsAccepted else {
            signupTermsError = "Agree to the Terms and the Privacy Policy first."
            return
        }
        guard let phone = validatedSignupPhone() else { return }

        let name = regName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = regEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = regPassword
        let role = selectedRole

        isBusy = true
        Task { @MainActor in
            do {
                let uid = try await AuthService.signUp(phone: phone, password: password)
                let created = User(
                    id: uid,
                    name: name,
                    email: email,
                    phone: phone,
                    password: "",
                    avatarColorHex: role == .owner ? "#2196F3" : "#4CAF50",
                    role: role,
                    gcashNumber: phone,
                    mayaNumber: "",
                    bankAccount: "",
                    qrPhEnabled: false,
                    termsAcceptedAt: Date()
                )
                do {
                    try await UserService.save(created)
                } catch {
                    try? await AuthService.deleteAuthUser()
                    throw error
                }
                startSession(uid: uid)
            } catch {
                isBusy = false
                let mapped = AuthService.map(error)
                if case .phoneInUse = mapped {
                    regPhoneError = mapped.localizedDescription
                } else {
                    showAlert("Can't create account", mapped.localizedDescription)
                }
            }
        }
    }

    func signUpWithGoogle() {
        showComingSoon("Google sign-up")
    }

    func signUpWithApple() {
        showComingSoon("Sign up with Apple")
    }

    // MARK: - Session

    private func startSession(uid: String) {
        stopListeners()
        var isFirstSnapshot = true
        userListener = UserService.listenToUser(uid: uid) { [weak self] loaded in
            guard let self else { return }
            if let loaded {
                currentUser = loaded
                licenseUploaded = loaded.licenseFileName != nil
                qrUploaded = loaded.qrFileName != nil
                if isFirstSnapshot {
                    isFirstSnapshot = false
                    finishLogin(role: loaded.role)
                }
            } else if isFirstSnapshot {
                isFirstSnapshot = false
                isBusy = false
                isRestoringSession = false
                logout()
                showAlert("Profile not found", "Your profile could not be loaded. Please log in again.")
            }
        } onError: { [weak self] error in
            guard let self else { return }
            if isFirstSnapshot {
                isFirstSnapshot = false
                isBusy = false
                isRestoringSession = false
                logout()
            }
            showAlert("Couldn't load your profile", error.localizedDescription)
        }
        allUsersListener = UserService.listenToAllUsers { [weak self] list in
            self?.users = list
        } onError: { [weak self] error in
            self?.showAlert("Couldn't load users", error.localizedDescription)
        }
    }

    private func finishLogin(role: UserRole) {
        selectedRole = role
        isLoggedIn = true
        isBusy = false
        isRestoringSession = false
        loginPassword = ""
        regPassword = ""
        savePrefs()
        removeOldLocalFiles()
        LocalNotificationService.shared.isEnabled = notificationsEnabled
        LocalNotificationService.shared.requestPermission()
    }

    private func stopListeners() {
        userListener?.remove()
        allUsersListener?.remove()
        userListener = nil
        allUsersListener = nil
    }

    func logout() {
        stopListeners()
        AuthService.signOut()
        selectedRole = currentUser?.role ?? .renter
        currentUser = nil
        users = []
        isLoggedIn = false
        authScreen = .login
        loginPassword = ""
        regPassword = ""
        showPassword = false
        signupTermsAccepted = false
        signupTermsError = nil
        deleteConfirmText = ""
        reauthPassword = ""
    }

    func displayName(id: String?, fallback: String = "") -> String {
        if let id {
            return user(id: id)?.name ?? "Deleted user"
        }
        return fallback.isEmpty ? "Deleted user" : fallback
    }

    // MARK: - Delete account

    func deleteAccount(cleanup: @escaping @MainActor () async -> Void) {
        pendingDeleteCleanup = cleanup
        Task { @MainActor in
            if await AuthService.needsRecentLogin() {
                reauthPassword = ""
                showReauthPrompt = true
            } else {
                await finishDeleteAccount()
            }
        }
    }

    func confirmReauthAndDelete() {
        let password = reauthPassword
        reauthPassword = ""
        guard !password.isEmpty else {
            showAlert("Password required", "Enter your password to delete your account.")
            return
        }
        isBusy = true
        Task { @MainActor in
            do {
                try await AuthService.reauthenticate(phone: user.phone, password: password)
                await finishDeleteAccount()
            } catch {
                isBusy = false
                showAlert("Can't delete account", AuthService.map(error).localizedDescription)
            }
        }
    }

    @MainActor
    private func finishDeleteAccount() async {
        guard let user = currentUser else { return }
        isBusy = true
        stopListeners()
        do {
            await pendingDeleteCleanup?()
            pendingDeleteCleanup = nil
            await PhotoService.deleteAll(in: "users/\(user.id)/private")
            await PhotoService.deleteAll(in: "users/\(user.id)/photos")
            try await UserService.delete(uid: user.id)
            try await AuthService.deleteAuthUser()
            isBusy = false
            logout()
        } catch {
            isBusy = false
            startSession(uid: user.id)
            showAlert("Can't delete account", AuthService.map(error).localizedDescription)
        }
    }

    // MARK: - Profile

    func toggleTheme() {
        theme = theme == .dark ? .light : .dark
        savePrefs()
    }

    func beginEditProfile() {
        editName = user.name
        editEmail = user.email
        editPhone = user.phone
        showAvatarColors = false
    }

    @discardableResult
    func saveProfile() -> Bool {
        let name = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = editEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            showAlert("Name required", "Enter your full name.")
            return false
        }
        guard AuthController.isValidEmail(email) else {
            showAlert("Invalid email", "Enter a valid email address.")
            return false
        }
        guard var updated = currentUser else { return false }
        updated.name = name
        updated.email = email
        persist(updated)
        return true
    }

    func setAvatarColor(_ hex: String) {
        guard var updated = currentUser else { return }
        updated.avatarColorHex = hex
        persist(updated)
        showAvatarColors = false
    }

    func beginPaymentMethods() {
        gcashDraft = user.gcashNumber
        mayaDraft = user.mayaNumber
        bankDraft = user.bankAccount
        qrPhDraft = user.qrPhEnabled
    }

    func savePaymentMethods() {
        guard var updated = currentUser else { return }
        updated.gcashNumber = gcashDraft
        updated.mayaNumber = mayaDraft
        updated.bankAccount = bankDraft
        updated.qrPhEnabled = qrPhDraft
        persist(updated)
    }

    func toggleNotifications() {
        notificationsEnabled.toggle()
        LocalNotificationService.shared.isEnabled = notificationsEnabled
        if !notificationsEnabled {
            LocalNotificationService.shared.cancelAllBookingReminders()
        }
        savePrefs()
    }

    // ID and license are private (users/{uid}/private). The payout QR is public to
    // signed-in users (users/{uid}/photos) so renters can scan it.
    func saveGovernmentID(_ image: UIImage) {
        uploadPhoto(image, path: "private/id") { user, reference in
            user.idFileName = reference
            user.isVerified = true
        }
    }

    func saveLicenseImage(_ image: UIImage) {
        uploadPhoto(image, path: "private/license") { [weak self] user, reference in
            user.licenseFileName = reference
            self?.licenseUploaded = true
        }
    }

    func saveQRImage(_ image: UIImage) {
        uploadPhoto(image, path: "photos/qr") { [weak self] user, reference in
            user.qrFileName = reference
            self?.qrUploaded = true
        }
    }

    private func uploadPhoto(_ image: UIImage, path: String, apply: @escaping (inout User, String) -> Void) {
        guard let uid = currentUser?.id else { return }
        isBusy = true
        Task { @MainActor in
            do {
                let reference = try await PhotoService.save(image, path: "users/\(uid)/\(path)")
                isBusy = false
                guard var updated = currentUser else { return }
                apply(&updated, reference)
                persist(updated)
            } catch {
                isBusy = false
                showAlert("Couldn't upload photo", error.localizedDescription)
            }
        }
    }

    // MARK: - Alerts

    func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
    }

    private func showComingSoon(_ feature: String) {
        showAlert("Coming soon", "\(feature) will be available soon. Use your phone number and password for now.")
    }

    // MARK: - Helpers

    private func persist(_ updated: User) {
        currentUser = updated
        Task { @MainActor in
            do {
                try await UserService.save(updated)
            } catch {
                showAlert("Couldn't save", error.localizedDescription)
            }
        }
    }

    private func validatedSignupPhone() -> String? {
        regNameError = nil
        regEmailError = nil
        regPhoneError = nil
        regPasswordError = nil

        let name = regName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = regEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = regPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        var isValid = true

        if name.isEmpty {
            regNameError = "Name is required."
            isValid = false
        }
        if email.isEmpty {
            regEmailError = "Email is required."
            isValid = false
        } else if !AuthController.isValidEmail(email) {
            regEmailError = "Enter a valid email address."
            isValid = false
        }
        if phone.isEmpty {
            regPhoneError = "Phone number is required."
            isValid = false
        } else if AuthController.normalizedPhone(phone) == nil {
            regPhoneError = "Use a PH number: 09XXXXXXXXX or +639XXXXXXXXX."
            isValid = false
        }
        if regPassword.count < 6 {
            regPasswordError = "Password must be at least 6 characters."
            isValid = false
        }

        guard isValid else { return nil }
        return AuthController.normalizedPhone(phone)
    }

    static func normalizedPhone(_ raw: String) -> String? {
        let compact = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        if compact.range(of: #"^09\d{9}$"#, options: .regularExpression) != nil {
            return compact
        }
        if compact.range(of: #"^\+639\d{9}$"#, options: .regularExpression) != nil {
            return "0" + compact.dropFirst(3)
        }
        return nil
    }

    static func isValidEmail(_ raw: String) -> Bool {
        raw.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil
    }

    private func savePrefs() {
        let defaults = UserDefaults.standard
        defaults.set(keepSignedIn, forKey: PrefKey.keepSignedIn)
        defaults.set(theme.rawValue, forKey: PrefKey.theme)
        defaults.set(notificationsEnabled, forKey: PrefKey.notifications)
    }

    private func removeOldLocalFiles() {
        StorageService.removeOldLocalData()
    }
}
