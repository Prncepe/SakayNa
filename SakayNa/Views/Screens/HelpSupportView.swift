import SwiftUI

struct HelpSupportView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var bookings: BookingController
    @Binding var path: NavigationPath
    @State private var openFAQ: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeader(title: "Help & Support", showsBack: true, showsProfileActions: false) {
                    path.removeLast()
                }

                Text("Frequently Asked Questions")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(palette.text)

                AppCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(bookings.faqs.enumerated()), id: \.offset) { index, faq in
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    openFAQ = openFAQ == index ? nil : index
                                } label: {
                                    HStack {
                                        Text(faq.question)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(palette.text)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        Image(systemName: openFAQ == index ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(palette.muted)
                                    }
                                }
                                .buttonStyle(.plain)
                                if openFAQ == index {
                                    Text(faq.answer)
                                        .font(.system(size: 14))
                                        .foregroundStyle(palette.muted)
                                }
                            }
                            .padding(16)
                            if index < bookings.faqs.count - 1 {
                                Divider().overlay(palette.border)
                            }
                        }
                    }
                }

                Text("Contact Us")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(palette.text)

                AppCard {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Support")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(palette.text)
                            Text("support@sakayna.ph")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hotline (24/7)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(palette.text)
                            Text("1-800-SAKAYNA")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
