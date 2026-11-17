import SwiftUI

struct LoginView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @State private var showForgotAlert = false
    @State private var showSignup = false
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        ZStack {
            palette.canvas.ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    BrandMark(size: 40)
                    Spacer()
                }
                .padding(.top, 8)

                MapHeroIllustration(compact: true)

                VStack(spacing: 6) {
                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(palette.text)
                    Text("Log in to book your next ride")
                        .font(.system(size: 14))
                        .foregroundStyle(palette.muted)
                }

                PillField(
                    placeholder: "09XXXXXXXXX",
                    systemImage: "phone",
                    keyboard: .phonePad,
                    text: $auth.loginPhone,
                    error: auth.loginPhoneError
                )

                PillField(
                    placeholder: "Password",
                    systemImage: "lock",
                    isSecure: !auth.showPassword,
                    text: $auth.loginPassword,
                    error: auth.loginPasswordError,
                    trailing: {
                        AnyView(
                            Button {
                                auth.showPassword.toggle()
                            } label: {
                                Image(systemName: auth.showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(palette.muted)
                            }
                            .buttonStyle(.plain)
                        )
                    }
                )

                HStack(spacing: 8) {
                    FilterChip(
                        title: "Rent a Vehicle",
                        isActive: auth.selectedRole == .renter,
                        fillsWidth: true
                    ) {
                        auth.selectedRole = .renter
                    }
                    FilterChip(
                        title: "List My Vehicle",
                        isActive: auth.selectedRole == .owner,
                        fillsWidth: true
                    ) {
                        auth.selectedRole = .owner
                    }
                }

                HStack {
                    Button(action: auth.toggleKeepSignedIn) {
                        HStack(spacing: 8) {
                            Image(systemName: auth.keepSignedIn ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(auth.keepSignedIn ? palette.yellow : palette.muted)
                            Text("Keep me signed in")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button("Forgot password?") {
                        showForgotAlert = true
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.muted)
                }

                PrimaryButton(title: "Log in", action: auth.login)

                SocialAuthRow(onGoogle: auth.loginWithGoogle, onApple: auth.loginWithApple)

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(palette.muted)
                    Button("Sign up") {
                        showSignup = true
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.text)
                }
                .font(.system(size: 13))

                HStack(spacing: 6) {
                    Button("Terms") { showTerms = true }
                    Text("·")
                        .foregroundStyle(palette.muted)
                    Button("Privacy Policy") { showPrivacy = true }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.muted)
                .padding(.bottom, 8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
        }
        .navigationDestination(isPresented: $showSignup) {
            SignupView()
        }
        .sheet(isPresented: $showTerms) {
            TermsScreenView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .alert("Password reset", isPresented: $showForgotAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Password reset will be available in the final project.")
        }
    }
}
