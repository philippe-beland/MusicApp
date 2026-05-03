import SwiftUI

struct FileListSection: View {
    let files: [File]
    let piece: Piece
    let work: Work

    @Environment(AudioPlayerManager.self) private var audioManager
    @State private var selectedPDF: File?

    private var audioURL: URL? {
        files.first(where: { $0.sourceType == .audio })?.storageURL
    }

    private var pdfFiles: [File] {
        files.filter { $0.sourceType == .pdfScore }
    }

    private var otherFiles: [File] {
        files.filter { $0.sourceType != .audio && $0.sourceType != .pdfScore }
    }

    private var hasAudio: Bool {
        audioURL != nil
    }

    private var isPlayingThisPiece: Bool {
        audioManager.nowPlayingPiece?.id == piece.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Play button
            Button {
                if isPlayingThisPiece {
                    audioManager.playPause()
                } else {
                    audioManager.play(piece: piece, work: work)
                }
            } label: {
                HStack {
                    Image(systemName: isPlayingThisPiece && audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                    Text(isPlayingThisPiece && audioManager.isPlaying ? "Pause" : "Play")
                        .font(.headline)
                }
                .foregroundStyle(hasAudio ? Color.accentColor : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.fill.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!hasAudio)

            // PDF scores grid
            if !pdfFiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sheet Music")
                        .font(.title3.bold())

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 12)
                    ], spacing: 12) {
                        ForEach(pdfFiles) { file in
                            let color = instrumentColor(for: file)
                            Button {
                                handleTap(file)
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "doc.richtext")
                                        .font(.largeTitle)
                                        .foregroundStyle(color)
                                    Text(fileLabel(for: file))
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .disabled(file.storageURL == nil)
                        }
                    }
                }
            }

            // Other files (MusicXML, MIDI, etc.)
            if !otherFiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Files")
                        .font(.title3.bold())

                    ForEach(otherFiles) { file in
                        fileRow(file)
                    }
                }
            }
        }
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
        case .pdfScore:
            if audioManager.nowPlayingPiece?.id != piece.id,
               let audioFile = piece.files?.first(where: { $0.sourceType == .audio }),
               let audioURL = audioFile.storageURL {
                audioManager.load(url: audioURL)
                audioManager.nowPlayingPiece = piece
                audioManager.nowPlayingWork = work
            }
            selectedPDF = file
        default:
            break
        }
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

    private func instrumentColor(for file: File) -> Color {
        guard let name = file.instrumentName?.lowercased() else { return .white }
        if name.contains("bass") { return .blue }
        if name.contains("guitar") { return .red }
        if name.contains("drum") || name.contains("percussion") { return .yellow }
        if name.contains("piano") || name.contains("keyboard") || name.contains("organ") { return .purple }
        return .white
    }

    private func fileLabel(for file: File) -> String {
        if file.sourceType == .pdfScore, let instrument = file.instrumentName {
            return instrument
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
