import SwiftUI

@main
struct MusicAppApp: App {
    @State private var authManager = AuthManager()
    @State private var dataProvider = DataProvider()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    ProgressView()
                } else if authManager.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environment(authManager)
            .environment(dataProvider)
            .task {
                await authManager.checkSession()
                await dataProvider.loadAll()
            }
        }
    }
}
