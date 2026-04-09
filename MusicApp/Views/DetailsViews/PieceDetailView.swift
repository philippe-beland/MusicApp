import SwiftUI

struct PieceDetailView: View {
    let piece: Piece
    let work: Work

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    WorkArtworkPlaceholder(work: work, height: 140)
                        .frame(maxWidth: 140)

                    Text(piece.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(work.artist.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(work.title)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)

                Divider()

                // Musical details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.title3.bold())

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 16) {
                        if let key = piece.keySignature {
                            DetailCard(label: "Key", value: key, icon: "music.note")
                        }
                        if let time = piece.timeSignature {
                            DetailCard(label: "Time", value: time, icon: "metronome")
                        }
                        if let bpm = piece.tempoBPM {
                            DetailCard(label: "Tempo", value: "\(Int(bpm)) BPM", icon: "speedometer")
                        }
                        if let ms = piece.durationMS {
                            let totalSeconds = ms / 1000
                            let min = totalSeconds / 60
                            let sec = totalSeconds % 60
                            DetailCard(label: "Duration", value: String(format: "%d:%02d", min, sec), icon: "clock")
                        }
                        if let form = piece.form {
                            DetailCard(label: "Form", value: form, icon: "rectangle.3.group")
                        }
                        if let feel = piece.feel {
                            DetailCard(label: "Feel", value: feel, icon: "waveform")
                        }
                    }
                }
                .padding(.horizontal)

                // Composer / contributors
                if piece.composer != nil || piece.lyricist != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Credits")
                            .font(.title3.bold())
                        if let composer = piece.composer {
                            MetadataRow(label: "Composer", value: composer)
                        }
                        if let lyricist = piece.lyricist {
                            MetadataRow(label: "Lyricist", value: lyricist)
                        }
                    }
                    .padding(.horizontal)
                }

                // Files (audio, PDF scores, etc.)
                if let files = piece.files, !files.isEmpty {
                    FileListSection(files: files, work: work)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle(piece.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Detail Card

struct DetailCard: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.fill.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


