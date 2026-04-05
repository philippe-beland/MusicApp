import SwiftUI

struct FileListSection: View {
    let files: [File]

    @State private var expandedAudioFile: File?
    @State private var selectedPDF: File?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Files")
                .font(.title3.bold())

            ForEach(files) { file in
                fileRow(file)
            }

            // Inline audio player
            if let audioFile = expandedAudioFile, let url = audioFile.storageURL {
                AudioPlayerView(url: url)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: expandedAudioFile?.id)
        .sheet(item: $selectedPDF) { file in
            if let url = file.storageURL {
                NavigationStack {
                    PDFViewerView(url: url)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { selectedPDF = nil }
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
                    Text(label(for: file.sourceType))
                        .font(.subheadline.weight(.medium))
                    if file.isPrimary {
                        Text("Primary")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isPlayable(file) {
                    Image(systemName: expandedAudioFile?.id == file.id ? "stop.fill" : "play.fill")
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
            if expandedAudioFile?.id == file.id {
                expandedAudioFile = nil
            } else {
                expandedAudioFile = file
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

    private func label(for type: SourceType) -> String {
        switch type {
        case .audio: "Audio"
        case .pdfScore: "PDF Score"
        case .musicxml: "MusicXML"
        case .musescore: "MuseScore"
        case .guitarPro: "Guitar Pro"
        case .midi: "MIDI"
        case .video: "Video"
        }
    }
}
