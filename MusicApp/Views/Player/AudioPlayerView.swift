import SwiftUI
import AVFoundation

enum PlaybackSpeed: CaseIterable, Identifiable {
    case half, twoThirds, threeQuarters, ninety, normal, oneAndQuarter, oneAndHalf, double

    var id: Float { rate }

    var rate: Float {
        switch self {
        case .half: 0.5
        case .twoThirds: 0.67
        case .threeQuarters: 0.75
        case .ninety: 0.9
        case .normal: 1.0
        case .oneAndQuarter: 1.25
        case .oneAndHalf: 1.5
        case .double: 2.0
        }
    }

    var label: String {
        switch self {
        case .half: "0.5x"
        case .twoThirds: "0.67x"
        case .threeQuarters: "0.75x"
        case .ninety: "0.9x"
        case .normal: "1x"
        case .oneAndQuarter: "1.25x"
        case .oneAndHalf: "1.5x"
        case .double: "2x"
        }
    }

    static func label(for rate: Float) -> String {
        allCases.first { $0.rate == rate }?.label ?? String(format: "%.2fx", rate)
    }
}

@Observable
class AudioPlayerManager {
    private var player: AVPlayer?
    private var timeObserver: Any?

    var isPlaying = false
    var isLoaded = false
    var currentTime: Double = 0
    var duration: Double = 0
    var playbackRate: Float = 1.0

    var nowPlayingPiece: Piece?
    var nowPlayingWork: Work?

    /// Play a piece's first audio file. Toggles play/pause if already playing this piece.
    func play(piece: Piece, work: Work) {
        if nowPlayingPiece?.id == piece.id {
            playPause()
            return
        }
        guard let audioFile = piece.files?.first(where: { $0.sourceType == .audio }),
              let url = audioFile.storageURL else { return }
        load(url: url)
        nowPlayingPiece = piece
        nowPlayingWork = work
        playPause()
    }

    func load(url: URL) {
        stop()
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        isLoaded = true

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
            player.rate = playbackRate
        }
        isPlaying.toggle()
    }

    func setRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
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
        isLoaded = false
        currentTime = 0
        duration = 0
        nowPlayingPiece = nil
        nowPlayingWork = nil
    }
}

// MARK: - Full inline player (used in PieceDetailView)

struct AudioPlayerView: View {
    let manager: AudioPlayerManager

    var body: some View {
        VStack(spacing: 12) {
            SeekBar(manager: manager)

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

            SpeedMenuView(manager: manager)
        }
        .padding()
        .background(.fill.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Compact mini player (used in PDF viewer)

struct MiniPlayerBar: View {
    let manager: AudioPlayerManager
    var showTitle: Bool = true

    var body: some View {
        VStack(spacing: 6) {
            SeekBar(manager: manager, height: 4)

            HStack(spacing: 12) {
                Button {
                    manager.playPause()
                } label: {
                    Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.body.weight(.semibold))
                }

                if showTitle, let piece = manager.nowPlayingPiece {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(piece.title)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                        if let work = manager.nowPlayingWork {
                            Text(work.artist.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Text(formatTime(manager.currentTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                SpeedMenuView(manager: manager)

                Button {
                    manager.stop()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Shared speed menu

struct SpeedMenuView: View {
    let manager: AudioPlayerManager

    var body: some View {
        HStack {
            Image(systemName: "speedometer")
                .font(.caption)
                .foregroundStyle(.secondary)
            Menu {
                ForEach(PlaybackSpeed.allCases) { speed in
                    Button {
                        manager.setRate(speed.rate)
                    } label: {
                        HStack {
                            Text(speed.label)
                            if manager.playbackRate == speed.rate {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(PlaybackSpeed.label(for: manager.playbackRate))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.fill.tertiary)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Seekable progress bar

struct SeekBar: View {
    let manager: AudioPlayerManager
    var height: CGFloat = 6

    @State private var isSeeking = false

    private var progress: Double {
        guard manager.duration > 0 else { return 0 }
        return manager.currentTime / manager.duration
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.fill.tertiary)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, geo.size.width * progress))
            }
            .frame(height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isSeeking = true
                        let fraction = min(max(value.location.x / geo.size.width, 0), 1)
                        manager.seek(to: fraction)
                    }
                    .onEnded { _ in
                        isSeeking = false
                    }
            )
        }
        .frame(height: height)
    }
}

// MARK: - Helpers

func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite && seconds >= 0 else { return "0:00" }
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}
