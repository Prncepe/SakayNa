import SwiftUI

struct MainTabView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var vehicles: VehicleController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var messages: MessageController
    @State private var homePath = NavigationPath()
    @State private var bookingsPath = NavigationPath()
    @State private var messagesPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    private var unreadMessages: Int {
        messages.unreadCount(for: auth.user.id)
    }

    private var showsFloatingBar: Bool {
        switch bookings.selectedTab {
        case .home: return homePath.isEmpty
        case .bookings: return bookingsPath.isEmpty
        case .messages: return messagesPath.isEmpty
        case .profile: return profilePath.isEmpty
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $bookings.selectedTab) {
                NavigationStack(path: $homePath) {
                    HomeView(path: $homePath)
                        .navigationDestination(for: AppRoute.self) { route in
                            homeDestination(route)
                        }
                }
                .tag(MainTab.home)
                .toolbar(.hidden, for: .tabBar)

                NavigationStack(path: $bookingsPath) {
                    MyBookingsView(path: $bookingsPath)
                        .navigationDestination(for: AppRoute.self) { route in
                            bookingsDestination(route)
                        }
                }
                .tag(MainTab.bookings)
                .toolbar(.hidden, for: .tabBar)

                NavigationStack(path: $messagesPath) {
                    MessagesListView(path: $messagesPath)
                        .navigationDestination(for: AppRoute.self) { route in
                            messagesDestination(route)
                        }
                }
                .tag(MainTab.messages)
                .badge(unreadMessages)
                .toolbar(.hidden, for: .tabBar)

                NavigationStack(path: $profilePath) {
                    ProfileView(path: $profilePath)
                        .navigationDestination(for: AppRoute.self) { route in
                            profileDestination(route)
                        }
                }
                .tag(MainTab.profile)
                .toolbar(.hidden, for: .tabBar)
            }

            if showsFloatingBar {
                FloatingTabBar(
                    selectedTab: $bookings.selectedTab,
                    unreadMessages: unreadMessages
                ) {
                    bookings.selectedTab = .home
                    homePath = NavigationPath()
                    vehicles.requestSearchFocus()
                }
                .padding(.bottom, 16)
            }

            if bookings.showNotifications {
                NotificationsPanelView()
            }
        }
        .onChange(of: bookings.homeResetToken) { _, _ in
            homePath = NavigationPath()
        }
        .onChange(of: bookings.bookingsResetToken) { _, _ in
            bookingsPath = NavigationPath()
        }
        .onChange(of: bookings.messagesResetToken) { _, _ in
            messagesPath = NavigationPath()
        }
        .onChange(of: bookings.profileResetToken) { _, _ in
            profilePath = NavigationPath()
        }
        .onChange(of: bookings.pendingDestination) { _, route in
            openPending(route)
        }
    }

    @ViewBuilder
    private func homeDestination(_ route: AppRoute) -> some View {
        switch route {
        case .allVehicles:
            AllVehiclesView(path: $homePath)
        case .vehicleDetail:
            VehicleDetailView(path: $homePath)
        case .booking:
            BookingView(path: $homePath)
        case .payment:
            PaymentView(path: $homePath)
        case .confirmation:
            BookingConfirmationView()
        case .chat(let id):
            ChatView(path: $homePath, conversationId: id)
        case .licenseUpload:
            LicenseUploadView(path: $homePath)
        case .receipt(let id):
            ReceiptView(path: $homePath, bookingId: id)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func bookingsDestination(_ route: AppRoute) -> some View {
        switch route {
        case .tripTracking(let id):
            TripTrackingView(path: $bookingsPath, bookingId: id)
        case .chat(let id):
            ChatView(path: $bookingsPath, conversationId: id)
        case .rateTrip(let id):
            RateTripView(path: $bookingsPath, bookingId: id)
        case .receipt(let id):
            ReceiptView(path: $bookingsPath, bookingId: id)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func messagesDestination(_ route: AppRoute) -> some View {
        switch route {
        case .chat(let id):
            ChatView(path: $messagesPath, conversationId: id)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func profileDestination(_ route: AppRoute) -> some View {
        switch route {
        case .editProfile:
            EditProfileView(path: $profilePath)
        case .paymentMethods:
            PaymentMethodsView(path: $profilePath)
        case .helpSupport:
            HelpSupportView(path: $profilePath)
        case .licenseUpload:
            LicenseUploadView(path: $profilePath)
        case .notificationSettings:
            NotificationSettingsView(path: $profilePath)
        case .termsAndConditions:
            TermsScreenView(path: $profilePath)
        case .privacyPolicy:
            PrivacyPolicyView(path: $profilePath)
        case .savedVehicles:
            SavedVehiclesView(path: $profilePath)
        case .vehicleDetail:
            VehicleDetailView(path: $profilePath)
        case .booking:
            BookingView(path: $profilePath)
        case .confirmation:
            BookingConfirmationView()
        case .chat(let id):
            ChatView(path: $profilePath, conversationId: id)
        case .about:
            AboutView(path: $profilePath)
        case .verifyAccount:
            VerifyAccountView(path: $profilePath)
        default:
            EmptyView()
        }
    }

    private func openPending(_ route: AppRoute?) {
        guard let route else { return }
        DispatchQueue.main.async {
            switch route {
            case .chat:
                bookings.selectedTab = .messages
                messagesPath.append(route)
            case .tripTracking, .rateTrip, .receipt:
                bookings.selectedTab = .bookings
                bookingsPath.append(route)
            case .allVehicles, .vehicleDetail, .booking, .payment, .confirmation, .licenseUpload:
                bookings.selectedTab = .home
                homePath.append(route)
            case .editProfile, .paymentMethods, .helpSupport, .notificationSettings,
                    .termsAndConditions, .privacyPolicy, .savedVehicles, .about, .verifyAccount:
                bookings.selectedTab = .profile
                profilePath.append(route)
            default:
                break
            }
            bookings.pendingDestination = nil
        }
    }
}
