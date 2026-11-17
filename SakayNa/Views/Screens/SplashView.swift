import SwiftUI

struct SplashView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController

    var body: some View {
        ZStack(alignment: .bottom) {
            palette.canvas.ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            palette.yellow.opacity(0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .offset(x: -120, y: -420)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                BrandMark(size: 46)
                    .padding(.top, 24)

                VStack(alignment: .leading, spacing: 14) {
                    Text("YOUR RIDE, YOUR RULES")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(palette.muted)
                    Text("Ride &\nDrive.")
                        .font(.system(size: 56, weight: .black))
                        .tracking(-1.8)
                        .foregroundStyle(palette.text)
                        .lineSpacing(-4)
                }
                .padding(.top, 44)

                Text("Find the perfect vehicle for every Philippine road trip.")
                    .font(.system(size: 15))
                    .foregroundStyle(palette.muted)
                    .padding(.top, 14)
                    .frame(maxWidth: 260, alignment: .leading)

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)

            VehicleImageView(
                imageName: "vios",
                customImageFile: nil,
                height: UIScreen.main.bounds.height * 0.28
            )
            .allowsHitTesting(false)
            .padding(.bottom, 96)

            SlideToConfirm(
                label: "Slide to Start",
                completedLabel: "Let's go!",
                playsHint: true
            ) {
                auth.goToLogin()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }
}
