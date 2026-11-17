import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    var path: Binding<NavigationPath>? = nil

    private let sections: [(String, String)] = [
        (
            "What we collect",
            "We collect your name, email, phone number, license/ID/OR-CR photos, bookings, and messages."
        ),
        (
            "Why we collect it",
            "We use this information to run bookings, verify users, and send notifications."
        ),
        (
            "Who sees it",
            "The other party in a booking can see the details needed to complete the rental, such as your name, phone, and booking information."
        ),
        (
            "How long we keep it",
            "We keep your data on this device until you delete your account."
        ),
        (
            "Your rights (RA 10173)",
            "Under the Data Privacy Act of 2012 (RA 10173), you can access, correct, delete, and object to the use of your personal data."
        ),
        (
            "Contact",
            "Questions about privacy: support@sakayna.example"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader(title: "Privacy Policy", showsBack: true, showsProfileActions: false) {
                    if let path, !path.wrappedValue.isEmpty {
                        path.wrappedValue.removeLast()
                    } else {
                        dismiss()
                    }
                }

                ForEach(sections, id: \.0) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.0)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.text)
                        Text(section.1)
                            .font(.system(size: 13))
                            .foregroundStyle(palette.muted)
                    }
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
