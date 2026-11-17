import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var messages: MessageController

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if auth.user.role == .owner {
                    OwnerTabView()
                } else {
                    MainTabView()
                }
            }
            .alert("SakayNa", isPresented: Binding(
                get: { bookings.alertMessage != nil },
                set: { if !$0 { bookings.alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { bookings.alertMessage = nil }
            } message: {
                Text(bookings.alertMessage ?? "")
            }

            Color.clear
                .frame(width: 0, height: 0)
                .alert("SakayNa", isPresented: Binding(
                    get: { messages.alertMessage != nil },
                    set: { if !$0 { messages.alertMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { messages.alertMessage = nil }
                } message: {
                    Text(messages.alertMessage ?? "")
                }

            DynamicNotificationOverlay(
                notification: bookings.islandNotification,
                onOpen: { item in
                    bookings.openNotification(item.id)
                },
                onDismiss: bookings.dismissIsland
            )
        }
        .overlay {
            if vehicles.isSaving || bookings.isSaving {
                LoadingOverlay(message: "Saving…")
            }
        }
        .alert("SakayNa", isPresented: Binding(
            get: { vehicles.alertMessage != nil },
            set: { if !$0 { vehicles.alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { vehicles.alertMessage = nil }
        } message: {
            Text(vehicles.alertMessage ?? "")
        }
        .onAppear {
            bookings.resetToHome()
        }
    }
}
