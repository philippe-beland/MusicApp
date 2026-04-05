import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(DataProvider.self) private var dataProvider

    var body: some View {
        NavigationStack {
            List {
                Section("Data Source") {
                    @Bindable var dp = dataProvider
                    Toggle("Use Sample Data", isOn: $dp.useSampleData)
                        .onChange(of: dataProvider.useSampleData) {
                            Task { await dataProvider.loadAll() }
                        }

                    if dataProvider.isLoading {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Loading...")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let error = dataProvider.error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Account") {
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
        .environment(DataProvider())
}
