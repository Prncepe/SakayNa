import Foundation
import FirebaseAuth

enum AuthServiceError: LocalizedError {
    case wrongCredentials
    case noInternet
    case tooManyAttempts
    case phoneInUse
    case needsRecentLogin
    case other(String)

    var errorDescription: String? {
        switch self {
        case .wrongCredentials:
            return "Wrong phone or password."
        case .noInternet:
            return "No internet connection. Check your network and try again."
        case .tooManyAttempts:
            return "Too many attempts. Try again later."
        case .phoneInUse:
            return "This phone number is already registered."
        case .needsRecentLogin:
            return "Enter your password again to delete your account."
        case .other(let message):
            return message
        }
    }
}

enum AuthService {
    static func hiddenEmail(from phone: String) -> String {
        "\(phone)@phone.sakayna.example"
    }

    static var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    static func signUp(phone: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().createUser(
                withEmail: hiddenEmail(from: phone),
                password: password
            )
            return result.user.uid
        } catch {
            throw map(error)
        }
    }

    static func signIn(phone: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().signIn(
                withEmail: hiddenEmail(from: phone),
                password: password
            )
            return result.user.uid
        } catch {
            throw map(error)
        }
    }

    static func signOut() {
        try? Auth.auth().signOut()
    }

    static func reauthenticate(phone: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        let credential = EmailAuthProvider.credential(
            withEmail: hiddenEmail(from: phone),
            password: password
        )
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw map(error)
        }
    }

    static func needsRecentLogin() async -> Bool {
        guard let user = Auth.auth().currentUser,
              let result = try? await user.getIDTokenResult() else { return true }
        return Date().timeIntervalSince(result.authDate) > 5 * 60
    }

    static func deleteAuthUser() async throws {
        guard let user = Auth.auth().currentUser else { return }
        do {
            try await user.delete()
        } catch {
            throw map(error)
        }
    }

    static func map(_ error: Error) -> AuthServiceError {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            return .noInternet
        }
        let code = AuthErrorCode(_bridgedNSError: ns)?.code
        switch code {
        case .wrongPassword, .userNotFound, .invalidEmail, .invalidCredential, .invalidRecipientEmail:
            return .wrongCredentials
        case .networkError:
            return .noInternet
        case .tooManyRequests:
            return .tooManyAttempts
        case .emailAlreadyInUse:
            return .phoneInUse
        case .requiresRecentLogin:
            return .needsRecentLogin
        default:
            let message = ns.localizedDescription.lowercased()
            if message.contains("network") || message.contains("internet") {
                return .noInternet
            }
            if message.contains("password") || message.contains("user") || message.contains("credential") {
                return .wrongCredentials
            }
            return .other(ns.localizedDescription)
        }
    }
}
