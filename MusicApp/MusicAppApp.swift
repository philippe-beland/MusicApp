import SwiftUI

@main
struct MusicAppApp: App {
    @State private var authManager = AuthManager()
    @State private var dataProvider = DataProvider()
    @State private var audioManager = AudioPlayerManager()

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
            .environment(audioManager)
            .task {
                await authManager.checkSession()
                await dataProvider.loadAll()
                audioManager.restoreState(from: dataProvider.works)
            }
        }
    }
}
