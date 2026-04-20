import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        NavigationStack {
            List {
                SwiftUI.Section("Account") {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            await auth.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environment(AuthManager())
}
