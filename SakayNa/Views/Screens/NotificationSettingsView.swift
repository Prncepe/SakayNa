import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController
    @Binding var path: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppHeader(title: "Notifications", showsBack: true, showsProfileActions: false) {
                if !path.isEmpty { path.removeLast() }
            }
            AppCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Push notifications")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.text)
                        Text("Approvals, pickup times, and trip updates")
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                    }
                    Spacer()
                    AppToggle(isOn: auth.notificationsEnabled) {
                        auth.toggleNotifications()
                        bookings.syncScheduledReminders()
                    }
                }
            }
            Spacer()
        }
        .padding(24)
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
