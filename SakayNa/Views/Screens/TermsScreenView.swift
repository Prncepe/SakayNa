import SwiftUI

struct TermsScreenView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var bookings: BookingController
    @EnvironmentObject private var vehicles: VehicleController
    var path: Binding<NavigationPath>? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader(title: "Terms & Conditions", showsBack: true, showsProfileActions: false) {
                    if let path, !path.wrappedValue.isEmpty {
                        path.wrappedValue.removeLast()
                    } else {
                        dismiss()
                    }
                }
                let role = auth.currentUser?.role ?? auth.selectedRole
                let items = role == .owner ? vehicles.ownerTerms : bookings.terms
                ForEach(items, id: \.self) { term in
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
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
