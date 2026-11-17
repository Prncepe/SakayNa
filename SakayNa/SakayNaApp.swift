import SwiftUI
import UIKit
import FirebaseCore

@main
struct SakayNaApp: App {
    @StateObject private var auth: AuthController
    @StateObject private var vehicles = VehicleController()
    @StateObject private var bookings = BookingController()
    @StateObject private var messages = MessageController()

    init() {
        FirebaseApp.configure()
        _auth = StateObject(wrappedValue: AuthController())
        UITabBar.appearance().isHidden = true
        LocalNotificationService.shared.configure()
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isRestoringSession {
                    ZStack {
                        ThemePalette.make(auth.theme).canvas.ignoresSafeArea()
                        LoadingOverlay(message: "Signing you in…")
                    }
                } else if auth.currentUser != nil {
                    ContentView()
                } else if auth.authScreen == .splash {
                    NavigationStack {
                        WelcomeView()
                    }
                } else if auth.authScreen == .signup {
                    NavigationStack {
                        SignupView()
                    }
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }
            .overlay {
                if auth.isBusy {
                    LoadingOverlay()
                }
            }
            .alert(auth.alertTitle, isPresented: Binding(
                get: { auth.alertMessage != nil },
                set: { if !$0 { auth.alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { auth.alertMessage = nil }
            } message: {
                Text(auth.alertMessage ?? "")
            }
            .environmentObject(auth)
            .environmentObject(vehicles)
            .environmentObject(bookings)
            .environmentObject(messages)
            .environment(\.palette, ThemePalette.make(auth.theme))
            .preferredColorScheme(auth.theme == .dark ? .dark : .light)
            .tint(ThemePalette.make(auth.theme).yellow)
            .onChange(of: scenePhase) { _, phase in
                LocalNotificationService.shared.isAppActive = phase == .active
            }
            .onChange(of: auth.currentUser?.id) { _, uid in
                if let uid {
                    vehicles.start(uid: uid)
                    vehicles.setFavorites(auth.user.favorites)
                    bookings.start(uid: uid)
                    messages.start(uid: uid)
                } else {
                    vehicles.stop()
                    bookings.stop()
                    messages.stop()
                }
            }
            .onChange(of: auth.currentUser?.favorites ?? []) { _, ids in
                vehicles.setFavorites(ids)
            }
        }
    }
}
