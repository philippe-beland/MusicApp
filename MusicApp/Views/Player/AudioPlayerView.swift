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
    private var endObserver: NSObjectProtocol?

    var isPlaying = false
    var isLoaded = false
    var currentTime: Double = 0
    var duration: Double = 0
    var playbackRate: Float = 1.0

    var volume: Float = 1.0
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
        player?.volume = volume
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
            // Save position every few seconds
            if let self, Int(self.currentTime) % 3 == 0 {
                self.saveState()
            }
        }

        // Auto-advance when piece ends
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.playNextInWork()
        }
    }

    /// Advance to the next piece in the current work, or stop if at the end.
    private func playNextInWork() {
        guard let work = nowPlayingWork,
              let currentPiece = nowPlayingPiece,
              let currentIndex = work.pieces.firstIndex(where: { $0.id == currentPiece.id }),
              currentIndex + 1 < work.pieces.count else {
            // End of work — stop playback
            stop()
            return
        }
        let nextPiece = work.pieces[currentIndex + 1]
        // Only advance if the next piece has audio
        guard nextPiece.files?.contains(where: { $0.sourceType == .audio }) == true else {
            stop()
            return
        }
        play(piece: nextPiece, work: work)
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

    func setVolume(_ value: Float) {
        volume = value
        player?.volume = value
    }

    func seek(to fraction: Double) {
        guard duration > 0 else { return }
        let target = CMTime(seconds: fraction * duration, preferredTimescale: 600)
        player?.seek(to: target)
    }

    /// Skip to the previous piece, or restart if more than 3 seconds in.
    func skipBackward() {
        if currentTime > 3 {
            player?.seek(to: .zero)
            return
        }
        guard let work = nowPlayingWork,
              let currentPiece = nowPlayingPiece,
              let currentIndex = work.pieces.firstIndex(where: { $0.id == currentPiece.id }),
              currentIndex > 0 else {
            player?.seek(to: .zero)
            return
        }
        let prevPiece = work.pieces[currentIndex - 1]
        guard prevPiece.files?.contains(where: { $0.sourceType == .audio }) == true else { return }
        play(piece: prevPiece, work: work)
    }

    /// Skip to the next piece in the work.
    func skipForward() {
        playNextInWork()
    }

    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        timeObserver = nil
        endObserver = nil
        player = nil
        isPlaying = false
        isLoaded = false
        currentTime = 0
        duration = 0
        nowPlayingPiece = nil
        nowPlayingWork = nil
        clearSavedState()
    }

    // MARK: - Persistence

    private enum Keys {
        static let pieceID = "player.pieceID"
        static let workID = "player.workID"
        static let position = "player.position"
    }

    func saveState() {
        guard let pieceID = nowPlayingPiece?.id,
              let workID = nowPlayingWork?.id else { return }
        UserDefaults.standard.set(pieceID.uuidString, forKey: Keys.pieceID)
        UserDefaults.standard.set(workID.uuidString, forKey: Keys.workID)
        UserDefaults.standard.set(currentTime, forKey: Keys.position)
    }

    private func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: Keys.pieceID)
        UserDefaults.standard.removeObject(forKey: Keys.workID)
        UserDefaults.standard.removeObject(forKey: Keys.position)
    }

    /// Restore the last played piece without auto-playing. Call after data is loaded.
    func restoreState(from works: [Work]) {
        guard let pieceString = UserDefaults.standard.string(forKey: Keys.pieceID),
              let workString = UserDefaults.standard.string(forKey: Keys.workID),
              let pieceID = UUID(uuidString: pieceString),
              let workID = UUID(uuidString: workString),
              let work = works.first(where: { $0.id == workID }),
              let piece = work.pieces.first(where: { $0.id == pieceID }),
              let audioFile = piece.files?.first(where: { $0.sourceType == .audio }),
              let url = audioFile.storageURL else { return }

        let savedPosition = UserDefaults.standard.double(forKey: Keys.position)

        load(url: url)
        nowPlayingPiece = piece
        nowPlayingWork = work

        // Seek to saved position once duration is known
        Task { @MainActor in
            // Wait briefly for the player item to be ready
            try? await Task.sleep(for: .milliseconds(500))
            if savedPosition > 0 && duration > 0 {
                let target = CMTime(seconds: min(savedPosition, duration), preferredTimescale: 600)
                await player?.seek(to: target)
            }
        }
    }
}

// MARK: - Full inline player (used in PieceDetailView)

struct AudioPlayerView: View {
    let manager: AudioPlayerManager

    var body: some View {
        VStack(spacing: 20) {
            // Track info
            if let piece = manager.nowPlayingPiece {
                VStack(spacing: 4) {
                    Text(piece.title)
                        .font(.headline)
                        .lineLimit(1)
                    if let work = manager.nowPlayingWork {
                        Text(work.artist.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Seek bar with timestamps
            VStack(spacing: 6) {
                SeekBar(manager: manager, height: 6)

                HStack {
                    Text(formatTime(manager.currentTime))
                    Spacer()
                    Text("-\(formatTime(max(0, manager.duration - manager.currentTime)))")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            // Transport controls
            HStack(spacing: 40) {
                Button { manager.skipBackward() } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }

                Button { manager.playPause() } label: {
                    Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                }

                Button { manager.skipForward() } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
            }
            .foregroundStyle(.primary)

            // Speed control
            SpeedMenuView(manager: manager)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Mini player bar (global bar)

struct MiniPlayerBar: View {
    let manager: AudioPlayerManager
    var showTitle: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Seekable progress bar
            SeekBar(manager: manager, height: 4)

            HStack(spacing: 12) {
                // Left: Artwork + Title
                HStack(spacing: 10) {
                    if let work = manager.nowPlayingWork {
                        WorkArtworkPlaceholder(work: work, height: 50)
                            .frame(width: 50)
                    }

                    if showTitle, let piece = manager.nowPlayingPiece {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(piece.title)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            if let work = manager.nowPlayingWork {
                                Text(work.artist.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)

                // Center: Transport controls + timing
                VStack(spacing: 2) {
                    HStack(spacing: 20) {
                        Button { manager.skipBackward() } label: {
                            Image(systemName: "backward.fill")
                                .font(.body)
                        }

                        Button { manager.playPause() } label: {
                            Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2.weight(.semibold))
                        }

                        Button { manager.skipForward() } label: {
                            Image(systemName: "forward.fill")
                                .font(.body)
                        }
                    }

                    HStack(spacing: 4) {
                        Text(formatTime(manager.currentTime))
                        Text("/")
                            .foregroundStyle(.tertiary)
                        Text(formatTime(manager.duration))
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                // Right: Speed, Volume
                SpeedMenuView(manager: manager)

                VolumeSliderView(manager: manager)
                    .frame(width: 110)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Shared speed menu

struct SpeedMenuView: View {
    let manager: AudioPlayerManager

    var body: some View {
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

// MARK: - Volume slider

struct VolumeSliderView: View {
    let manager: AudioPlayerManager

    var body: some View {
        HStack(spacing: 6) {
            Button {
                manager.setVolume(manager.volume == 0 ? 1.0 : 0)
            } label: {
                Image(systemName: volumeIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
            }
            .buttonStyle(.plain)

            Slider(value: Binding(
                get: { Double(manager.volume) },
                set: { manager.setVolume(Float($0)) }
            ), in: 0...1)
            .tint(.white.opacity(0.7))
        }
    }

    private var volumeIcon: String {
        if manager.volume == 0 { return "speaker.slash.fill" }
        if manager.volume < 0.33 { return "speaker.fill" }
        if manager.volume < 0.66 { return "speaker.wave.1.fill" }
        return "speaker.wave.3.fill"
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

    private var barHeight: CGFloat {
        isSeeking ? height * 1.8 : height
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.fill.tertiary)
                    .frame(height: barHeight)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, geo.size.width * progress), height: barHeight)

                // Thumb handle
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: isSeeking ? 20 : 12, height: isSeeking ? 20 : 12)
                    .shadow(radius: 2)
                    .offset(x: max(0, geo.size.width * progress - (isSeeking ? 10 : 6)))
            }
            .frame(height: 30)
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
            .animation(.easeOut(duration: 0.15), value: isSeeking)
        }
        .frame(height: 30)
    }
}

// MARK: - Helpers

func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite && seconds >= 0 else { return "0:00" }
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}
