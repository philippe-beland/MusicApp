import SwiftUI

struct FileListSection: View {
    let files: [File]
    let work: Work

    @Environment(AudioPlayerManager.self) private var audioManager
    @State private var selectedPDF: File?

    private var audioURL: URL? {
        files.first(where: { $0.sourceType == .audio })?.storageURL
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Files")
                .font(.title3.bold())

            ForEach(files) { file in
                fileRow(file)
            }

            // Inline audio player when playing a file from this piece
            if let piece = audioManager.nowPlayingPiece,
               files.contains(where: { file in file.sourceType == .audio && piece.files?.contains(where: { f in f.id == file.id }) ?? false }),
               audioManager.isLoaded {
                AudioPlayerView(manager: audioManager)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: audioManager.nowPlayingPiece?.id)
        .fullScreenCover(item: $selectedPDF) { file in
            if let url = file.storageURL {
                NavigationStack {
                    ZStack(alignment: .bottom) {
                        PDFViewerView(url: url)
                            .ignoresSafeArea(edges: .bottom)

                        if audioManager.isLoaded {
                            MiniPlayerBar(manager: audioManager)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { selectedPDF = nil }
                        }
                        if files.contains(where: { $0.sourceType == .audio }),
                           !audioManager.isLoaded,
                           let audioURL {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    audioManager.load(url: audioURL)
                                    audioManager.playPause()
                                } label: {
                                    Image(systemName: "play.circle")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fileRow(_ file: File) -> some View {
        Button {
            handleTap(file)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconName(for: file.sourceType))
                    .font(.title3)
                    .foregroundStyle(iconColor(for: file.sourceType))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(fileLabel(for: file))
                        .font(.subheadline.weight(.medium))
                    if file.isPrimary {
                        Text("Primary")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isPlayable(file) {
                    Image(systemName: audioManager.nowPlayingPiece != nil && audioManager.isPlaying ? "stop.fill" : "play.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if file.sourceType == .pdfScore {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.fill.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(file.storageURL == nil)
    }

    private func handleTap(_ file: File) {
        switch file.sourceType {
        case .audio:
            if let url = file.storageURL {
                if audioManager.isLoaded {
                    audioManager.stop()
                } else {
                    audioManager.load(url: url)
                    audioManager.playPause()
                }
            }
        case .pdfScore:
            selectedPDF = file
        default:
            break
        }
    }

    private func isPlayable(_ file: File) -> Bool {
        file.sourceType == .audio
    }

    private func iconName(for type: SourceType) -> String {
        switch type {
        case .audio: "speaker.wave.2.fill"
        case .pdfScore: "doc.richtext"
        case .musicxml: "doc.text"
        case .musescore: "music.note.list"
        case .guitarPro: "guitars"
        case .midi: "pianokeys"
        case .video: "film"
        }
    }

    private func iconColor(for type: SourceType) -> Color {
        switch type {
        case .audio: .blue
        case .pdfScore: .red
        case .musicxml: .orange
        case .video: .purple
        default: .secondary
        }
    }

    private func fileLabel(for file: File) -> String {
        if file.sourceType == .pdfScore, let instrument = file.instrumentName {
            return "PDF Score — \(instrument)"
        }
        switch file.sourceType {
        case .audio: return "Audio"
        case .pdfScore: return "PDF Score"
        case .musicxml: return "MusicXML"
        case .musescore: return "MuseScore"
        case .guitarPro: return "Guitar Pro"
        case .midi: return "MIDI"
        case .video: return "Video"
        }
    }
}
