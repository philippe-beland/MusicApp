import SwiftUI
import AVFoundation

@Observable
class AudioPlayerManager {
    private var player: AVPlayer?
    private var timeObserver: Any?

    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0

    func load(url: URL) {
        stop()
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)

        // Observe duration once ready
        Task { @MainActor in
            guard let item = player?.currentItem else { return }
            let dur = try? await item.asset.load(.duration)
            if let dur, dur.isNumeric {
                duration = CMTimeGetSeconds(dur)
            }
        }

        // Periodic time updates
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
    }

    func playPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    func seek(to fraction: Double) {
        guard duration > 0 else { return }
        let target = CMTime(seconds: fraction * duration, preferredTimescale: 600)
        player?.seek(to: target)
    }

    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        timeObserver = nil
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }
}

struct AudioPlayerView: View {
    let url: URL
    @State private var manager = AudioPlayerManager()

    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            ProgressView(value: manager.duration > 0 ? manager.currentTime / manager.duration : 0)
                .tint(.accentColor)

            HStack {
                Text(formatTime(manager.currentTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    manager.playPause()
                } label: {
                    Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                }

                Spacer()

                Text(formatTime(manager.duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.fill.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { manager.load(url: url) }
        .onDisappear { manager.stop() }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
