import SwiftUI
import MusicKit

struct MusicPlayerControls: View {
    @ObservedObject var state = ApplicationMusicPlayer.shared.state
    @ObservedObject var queue = ApplicationMusicPlayer.shared.queue
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            // Song info section
            if let currentEntry = queue.currentEntry {
                    HStack(spacing: 12) {
                        if let songArtwork = currentEntry.artwork {
                            ArtworkImage(songArtwork, height: 40)
                        } else {
                            // Song artwork placeholder (since we can't access artwork from queue entry)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // Song title and artist
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentEntry.title)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)

                            Text(currentEntry.subtitle ?? "")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                            // Time display
                            HStack(spacing: 4) {
                                Text(formatTime(currentTime))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("/")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
//                                Text(formatTime(currentEntry.item. ?? 0))
//                                    .font(.system(size: 10))
//                                    .foregroundColor(.secondary)
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    Divider()
                        .padding(.horizontal, 16)
            } else {
                Text("No current entry")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
            
            // Playback controls
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
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .padding(.bottom, 32)
        .padding(.horizontal, 24)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // Helper function to format time
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Timer functions
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = ApplicationMusicPlayer.shared.playbackTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
