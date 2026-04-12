import SwiftUI

struct ContentView: View {
    @Environment(AudioPlayerManager.self) private var audioManager

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "music.note")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .padding(.bottom, audioManager.isLoaded ? 56 : 0)

            if audioManager.isLoaded {
                VStack(spacing: 0) {
                    Divider()
                    MiniPlayerBar(manager: audioManager)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: audioManager.isLoaded)
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
        .environment(DataProvider())
        .environment(AudioPlayerManager())
}
