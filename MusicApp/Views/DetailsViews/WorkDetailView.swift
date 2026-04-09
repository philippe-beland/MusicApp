import SwiftUI

struct WorkDetailView: View {
    let work: Work
    @Environment(AudioPlayerManager.self) private var audioManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Artwork + info header
                VStack(spacing: 16) {
                    WorkArtworkPlaceholder(work: work, height: 220)
                        .frame(maxWidth: 220)

                    VStack(spacing: 6) {
                        Text(work.title)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text(work.artist.name)
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            TagBadge(text: work.workType.rawValue.capitalized)
                            TagBadge(text: work.genre.rawValue.capitalized)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top)

                Divider()
                    .padding(.horizontal)

                // Details
                WorkMetadataSection(work: work)

                // Pieces
                if !work.pieces.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(work.workType == .symphony ? "Movements" : "Tracks")
                            .font(.title3.bold())
                            .padding(.horizontal)
                            .padding(.bottom, 4)

                        ForEach(Array(work.pieces.enumerated()), id: \.element.id) { index, piece in
                            PieceListRow(
                                piece: piece,
                                work: work,
                                index: index,
                                isPlaying: audioManager.nowPlayingPiece?.id == piece.id && audioManager.isPlaying,
                                onPlay: { audioManager.play(piece: piece, work: work) }
                            )
                        }
                    }
                }
            }
            .padding(.bottom)
        }
        .navigationTitle(work.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Tag Badge

struct TagBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.fill.tertiary)
            .clipShape(Capsule())
    }
}

// MARK: - Metadata Section

struct WorkMetadataSection: View {
    let work: Work

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let opus = work.opus {
                MetadataRow(label: "Opus", value: opus)
            }
            if let label = work.label {
                MetadataRow(label: "Label", value: label)
            }
            if let producer = work.producer {
                MetadataRow(label: "Producer", value: producer)
            }
            if let studio = work.recordingStudio {
                MetadataRow(label: "Studio", value: studio)
            }
            if let premiere = work.premiereLocation {
                MetadataRow(label: "Premiere", value: premiere)
            }
            if let director = work.director {
                MetadataRow(label: "Director", value: director)
            }
            if !work.awards.isEmpty {
                MetadataRow(label: "Awards", value: work.awards.joined(separator: ", "))
            }
            if let notes = work.notes {
                MetadataRow(label: "Notes", value: notes)
            }
        }
        .padding(.horizontal)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Piece Row

struct PieceListRow: View {
    let piece: Piece
    let work: Work
    let index: Int
    var isPlaying: Bool = false
    var onPlay: (() -> Void)?

    private var hasAudio: Bool {
        piece.files?.contains(where: { $0.sourceType == .audio }) ?? false
    }

    var body: some View {
        HStack(spacing: 0) {
            // Tap area: play audio
            Button {
                onPlay?()
            } label: {
                HStack {
                    Group {
                        if isPlaying {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(.tint)
                                .font(.caption)
                        } else {
                            Text("\(index + 1)")
                                .foregroundStyle(hasAudio ? .primary : .secondary)
                        }
                    }
                    .font(.subheadline)
                    .frame(width: 28, alignment: .trailing)

                    Text(piece.title)
                        .font(.body)
                        .foregroundStyle(isPlaying ? Color.accentColor : .primary)
                        .lineLimit(1)

                    Spacer()

                    if let ms = piece.durationMS {
                        Text(formatDuration(ms))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!hasAudio)

            // Info button → detail view
            NavigationLink(destination: PieceDetailView(piece: piece, work: work)) {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDuration(_ ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


