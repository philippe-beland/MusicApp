import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(DataProvider.self) private var dataProvider

    @State private var email = ""
    @State private var password = ""
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // App branding
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)
                    Text("MusicApp")
                        .font(.largeTitle.bold())
                    Text("Your music analysis library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            await auth.signIn(email: email, password: password)
                        }
                    } label: {
                        Text("Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal)

                Spacer()

                // Skip option
                Button {
                    dataProvider.useSampleData = true
                    Task { await dataProvider.loadAll() }
                    auth.isAuthenticated = true
                } label: {
                    Text("Continue with Sample Data")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 24)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
        .environment(DataProvider())
}
