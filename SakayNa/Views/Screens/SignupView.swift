import SwiftUI

struct SignupView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthController
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        ZStack {
            palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        BrandMark(size: 40)
                        Spacer()
                    }
                    .padding(.top, 8)

                    MapHeroIllustration(compact: true)

                    VStack(spacing: 6) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(palette.text)
                        Text("Sign up to start riding or listing")
                            .font(.system(size: 14))
                            .foregroundStyle(palette.muted)
                    }

                    PillField(
                        placeholder: "Full name",
                        systemImage: "person",
                        text: $auth.regName,
                        error: auth.regNameError
                    )
                    PillField(
                        placeholder: "Email address",
                        systemImage: "envelope",
                        keyboard: .emailAddress,
                        text: $auth.regEmail,
                        error: auth.regEmailError
                    )
                    PillField(
                        placeholder: "09XXXXXXXXX or +639XXXXXXXXX",
                        systemImage: "phone",
                        keyboard: .phonePad,
                        text: $auth.regPhone,
                        error: auth.regPhoneError
                    )
                    PillField(
                        placeholder: "Password (at least 6 characters)",
                        systemImage: "lock",
                        isSecure: !auth.showPassword,
                        text: $auth.regPassword,
                        error: auth.regPasswordError,
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

                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            auth.signupTermsAccepted.toggle()
                        } label: {
                            Image(systemName: auth.signupTermsAccepted ? "checkmark.square.fill" : "square")
                                .foregroundStyle(auth.signupTermsAccepted ? palette.yellow : palette.muted)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("I agree to the")
                                .font(.system(size: 13))
                                .foregroundStyle(palette.muted)
                            HStack(spacing: 4) {
                                Button("Terms") { showTerms = true }
                                Text("and the")
                                    .foregroundStyle(palette.muted)
                                Button("Privacy Policy") { showPrivacy = true }
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(palette.text)
                        }
                    }

                    if let error = auth.signupTermsError {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(palette.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(
                        title: "Create account",
                        isEnabled: auth.signupTermsAccepted,
                        action: auth.signUp
                    )

                    SocialAuthRow(onGoogle: auth.signUpWithGoogle, onApple: auth.signUpWithApple)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(palette.muted)
                        Button("Log in") {
                            dismiss()
                        }
                            .fontWeight(.semibold)
                            .foregroundStyle(palette.text)
                    }
                    .font(.system(size: 13))
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 28)
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsScreenView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }
}
