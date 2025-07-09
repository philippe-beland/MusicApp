import SwiftUI
import MusicKit

struct MusicPlayerControls: View {
    @ObservedObject var state = ApplicationMusicPlayer.shared.state

    var body: some View {
        HStack(spacing: 32) {
            Button(action: {
                Task { try? await ApplicationMusicPlayer.shared.skipToPreviousEntry() }
            }) {
                Image(systemName: "backward.fill")
                    .font(.title2)
            }
            PlayButton(isPlaying: state.playbackStatus == .playing) {
                if state.playbackStatus == .playing {
                    ApplicationMusicPlayer.shared.pause()
                } else {
                    Task { try? await ApplicationMusicPlayer.shared.play() }
                }
            }
            Button(action: {
                Task { try? await ApplicationMusicPlayer.shared.skipToNextEntry() }
            }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(radius: 8)
        .padding(.bottom, 32)
        .padding(.horizontal, 24)
    }
}

struct PlayButton: View {
    var isPlaying: Bool
    var font: Font = .title2
    var padding: CGFloat = 20
    var action: () -> ()

    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(font)
                .padding(padding)
                .background(Circle().opacity(0.1))
        }
    }
}
