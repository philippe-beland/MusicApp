import SwiftUI

struct WorkDetailView: View {
    let work: Work
    @Environment(AudioPlayerManager.self) private var audioManager
    @Environment(DataProvider.self) private var dataProvider
    @State private var showingEdit = false
    @State private var showingNewPiece = false
    @State private var showingFilters = false

    private var liveWork: Work {
        dataProvider.works.first(where: { $0.id == work.id }) ?? work
    }

    private var displayedPieces: [Piece] {
        guard dataProvider.isFiltering else { return liveWork.pieces }
        return liveWork.pieces.filter { dataProvider.piecePassesFilters($0) }
    }

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

                if showingFilters {
                    StatusFilterBar()
                        .padding(.horizontal)
                }

                // Pieces
                if !displayedPieces.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(work.workType == .symphony ? "Movements" : "Tracks")
                            .font(.title3.bold())
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        VStack(spacing: 1) {
                            ForEach(displayedPieces) { piece in
                                let originalIndex = liveWork.pieces.firstIndex(where: { $0.id == piece.id }) ?? 0
                                PieceListRow(
                                    piece: piece,
                                    work: liveWork,
                                    index: originalIndex,
                                    isPlaying: audioManager.nowPlayingPiece?.id == piece.id && audioManager.isPlaying,
                                    onPlay: { audioManager.play(piece: piece, work: liveWork) }
                                )
                            }
                        }
                        .background(.fill.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom)
        }
        .navigationTitle(work.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            StatusFilterToolbar(showingFilters: $showingFilters)
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button {
                        showingNewPiece = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    Button("Edit") { showingEdit = true }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            WorkEditView(work: work)
        }
        .sheet(isPresented: $showingNewPiece) {
            NewPieceView(work: work)
        }
    }
}

// MARK: - Work Edit View

struct WorkEditView: View {
    @Environment(DataProvider.self) private var dataProvider
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var workType: WorkType
    @State private var genre: Genre
    @State private var releaseDate: Date
    @State private var hasReleaseDate: Bool
    @State private var opus: String
    @State private var label: String
    @State private var producer: String
    @State private var studio: String
    @State private var director: String
    @State private var premiere: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    let work: Work

    init(work: Work) {
        self.work = work
        _title = State(initialValue: work.title)
        _workType = State(initialValue: work.workType)
        _genre = State(initialValue: work.genre)
        _releaseDate = State(initialValue: work.releaseDate ?? Date())
        _hasReleaseDate = State(initialValue: work.releaseDate != nil)
        _opus = State(initialValue: work.opus ?? "")
        _label = State(initialValue: work.label ?? "")
        _producer = State(initialValue: work.producer ?? "")
        _studio = State(initialValue: work.recordingStudio ?? "")
        _director = State(initialValue: work.director ?? "")
        _premiere = State(initialValue: work.premiereLocation ?? "")
        _notes = State(initialValue: work.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("General") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $workType) {
                        ForEach(WorkType.allCases, id: \.self) { t in
                            Text(t.rawValue.capitalized).tag(t)
                        }
                    }
                    Picker("Genre", selection: $genre) {
                        ForEach(Genre.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                    Toggle("Release Date", isOn: $hasReleaseDate)
                    if hasReleaseDate {
                        DatePicker("Date", selection: $releaseDate, displayedComponents: .date)
                    }
                }

                SwiftUI.Section("Details") {
                    TextField("Opus", text: $opus)
                    TextField("Label", text: $label)
                    TextField("Producer", text: $producer)
                    TextField("Studio", text: $studio)
                    TextField("Director", text: $director)
                    TextField("Premiere Location", text: $premiere)
                }

                SwiftUI.Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = errorMessage {
                    SwiftUI.Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Work")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                var updated = work
                updated.title = title
                updated.workType = workType
                updated.genre = genre
                updated.releaseDate = hasReleaseDate ? releaseDate : nil
                updated.opus = opus.isEmpty ? nil : opus
                updated.label = label.isEmpty ? nil : label
                updated.producer = producer.isEmpty ? nil : producer
                updated.recordingStudio = studio.isEmpty ? nil : studio
                updated.director = director.isEmpty ? nil : director
                updated.premiereLocation = premiere.isEmpty ? nil : premiere
                updated.notes = notes.isEmpty ? nil : notes
                try await dataProvider.saveWork(updated)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
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

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let date = work.releaseDate {
                MetadataRow(label: "Release Date", value: Self.displayFormatter.string(from: date))
            }
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

    private var pdfCount: Int {
        piece.files?.filter { $0.sourceType == .pdfScore }.count ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Track number / play button
            Button {
                onPlay?()
            } label: {
                ZStack {
                    if isPlaying {
                        Image(systemName: "pause.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                    } else {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .foregroundStyle(hasAudio ? .primary : .tertiary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(!hasAudio)

            // Title + metadata
            NavigationLink(destination: PieceDetailView(piece: piece, work: work)) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(piece.title)
                            .font(.body)
                            .foregroundStyle(isPlaying ? Color.accentColor : .primary)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            if let ms = piece.durationMS {
                                Text(formatDuration(ms))
                            }
                            if let key = piece.keySignature {
                                Text("·")
                                Text(key)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Badges
                    HStack(spacing: 6) {
                        if pdfCount > 0 {
                            Label("\(pdfCount)", systemImage: "doc.richtext")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if let sections = piece.sections, !sections.isEmpty {
                            Label("\(sections.count)", systemImage: "list.bullet")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isPlaying ? Color.accentColor.opacity(0.08) : .clear)
    }

    private func formatDuration(_ ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - New Piece View

struct NewPieceView: View {
    @Environment(DataProvider.self) private var dataProvider
    @Environment(\.dismiss) private var dismiss

    let work: Work
    @State private var title = ""
    @State private var pieceNumber = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("General") {
                    TextField("Title", text: $title)
                    TextField("Track Number", text: $pieceNumber)
                        .keyboardType(.numberPad)
                }

                if let error = errorMessage {
                    SwiftUI.Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }

    private func create() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await dataProvider.createPiece(
                    workId: work.id,
                    title: title,
                    pieceNumber: Int(pieceNumber)
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
