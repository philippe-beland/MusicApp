import SwiftUI

struct WorkDetailView: View {
    let work: Work

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
                    VStack(alignment: .leading, spacing: 12) {
                        Text(work.workType == .symphony ? "Movements" : "Tracks")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        ForEach(Array(work.pieces.enumerated()), id: \.element.id) { index, piece in
                            NavigationLink(destination: PieceDetailView(piece: piece, work: work)) {
                                PieceListRow(piece: piece, index: index)
                            }
                            .buttonStyle(.plain)
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
    let index: Int

    var body: some View {
        HStack {
            Text("\(index + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)

            Text(piece.title)
                .font(.body)
                .lineLimit(1)

            Spacer()

            if let ms = piece.durationMS {
                Text(formatDuration(ms))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
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

#Preview {
    NavigationStack {
        WorkDetailView(work: SampleData.interstellar)
    }
}
