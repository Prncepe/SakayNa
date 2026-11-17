import SwiftUI

struct AboutView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @Binding var path: NavigationPath

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppHeader(title: "About", showsBack: true, showsProfileActions: false) {
                if !path.isEmpty { path.removeLast() }
            }

            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SakayNa")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(palette.text)
                    Text("Version \(version)")
                        .font(.system(size: 15))
                        .foregroundStyle(palette.muted)
                    Text("Made for ITWM105")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(palette.yellow)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            OutlineButton(title: "Send test reminder (10 seconds)") {
                LocalNotificationService.shared.scheduleTestReminder()
            }
            if !auth.notificationsEnabled {
                Text("Turn on notifications in Profile first.")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.muted)
            }
            Spacer()
        }
        .padding(24)
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
