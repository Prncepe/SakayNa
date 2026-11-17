import SwiftUI

struct EditProfileView: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var auth: AuthController
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AppHeader(title: "Edit Profile", showsBack: true, showsProfileActions: false) {
                    path.removeLast()
                }

                Form {
                    Section {
                        HStack {
                            Spacer()
                            Button {
                                auth.showAvatarColors.toggle()
                            } label: {
                                Text(String(auth.editName.prefix(1)).uppercased())
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 80, height: 80)
                                    .background(Color(hexString: auth.user.avatarColorHex))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)

                        if auth.showAvatarColors {
                            HStack {
                                Spacer()
                                ForEach(User.avatarPresets, id: \.self) { hex in
                                    Button {
                                        auth.setAvatarColor(hex)
                                    } label: {
                                        Circle()
                                            .fill(Color(hexString: hex))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle().stroke(
                                                    auth.user.avatarColorHex == hex ? palette.text : Color.clear,
                                                    lineWidth: 2
                                                )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                        }
                    }

                    Section {
                        TextField("Full name", text: $auth.editName)
                        TextField("Email", text: $auth.editEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        HStack {
                            Text(auth.editPhone)
                                .foregroundStyle(palette.muted)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .foregroundStyle(palette.muted)
                        }
                    } header: {
                        Text("Profile")
                    } footer: {
                        Text("Your phone number is your login and can't be changed.")
                    }
                }
                .frame(minHeight: 420)
                .scrollContentBackground(.hidden)

                PrimaryButton(title: "Save Changes") {
                    if auth.saveProfile() {
                        path.removeLast()
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(palette.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
