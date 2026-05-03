import SwiftUI

struct PieceDetailView: View {
    let piece: Piece
    let work: Work
    @Environment(DataProvider.self) private var dataProvider
    @Environment(AudioPlayerManager.self) private var audioManager
    @State private var showingEdit = false

    /// Live piece from the data provider (reflects DB changes), falling back to the snapshot.
    private var livePiece: Piece {
        dataProvider.works
            .flatMap(\.pieces)
            .first(where: { $0.id == piece.id }) ?? piece
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    WorkArtworkPlaceholder(work: work, height: 140)
                        .frame(maxWidth: 140)

                    Text(livePiece.title)
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

                // Status toggles
                PieceStatusRow(piece: livePiece)
                    .padding(.horizontal)

                Divider()

                // Musical details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.title3.bold())

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 16) {
                        if let key = livePiece.keySignature {
                            DetailCard(label: "Key", value: key, icon: "music.note")
                        }
                        if let time = livePiece.timeSignature {
                            DetailCard(label: "Time", value: time, icon: "metronome")
                        }
                        if let bpm = livePiece.tempoBPM {
                            DetailCard(label: "Tempo", value: "\(Int(bpm)) BPM", icon: "speedometer")
                        }
                        if let ms = livePiece.durationMS {
                            let totalSeconds = ms / 1000
                            let min = totalSeconds / 60
                            let sec = totalSeconds % 60
                            DetailCard(label: "Duration", value: String(format: "%d:%02d", min, sec), icon: "clock")
                        }
                        if let form = livePiece.form {
                            DetailCard(label: "Form", value: form, icon: "rectangle.3.group")
                        }
                        if let feel = livePiece.feel {
                            DetailCard(label: "Feel", value: feel, icon: "waveform")
                        }
                    }
                }
                .padding(.horizontal)

                // Composer / contributors
                if livePiece.composer != nil || livePiece.lyricist != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Credits")
                            .font(.title3.bold())
                        if let composer = livePiece.composer {
                            MetadataRow(label: "Composer", value: composer)
                        }
                        if let lyricist = livePiece.lyricist {
                            MetadataRow(label: "Lyricist", value: lyricist)
                        }
                    }
                    .padding(.horizontal)
                }

                // Sections
                if let sections = livePiece.sections, !sections.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sections")
                            .font(.title3.bold())

                        ForEach(sections) { section in
                            SectionRowView(section: section, depth: 0, onDelete: { sectionId in
                                Task {
                                    try? await deleteSection(id: sectionId)
                                    await dataProvider.loadAll()
                                }
                            }, onSeek: { ms in
                                seekToMs(ms)
                            })
                        }
                    }
                    .padding(.horizontal)
                }

                // Files (audio, PDF scores, etc.)
                if let files = livePiece.files, !files.isEmpty {
                    FileListSection(files: files, piece: livePiece, work: work)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle(livePiece.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            PieceEditView(piece: piece)
        }
    }

    private func seekToMs(_ ms: Double) {
        // Load piece audio if not already playing this piece
        if audioManager.nowPlayingPiece?.id != livePiece.id {
            audioManager.play(piece: livePiece, work: work)
        }
        guard audioManager.duration > 0 else { return }
        let fraction = (ms / 1000.0) / audioManager.duration
        audioManager.seek(to: min(max(fraction, 0), 1))
    }
}

// MARK: - Piece Edit View

struct PieceEditView: View {
    @Environment(DataProvider.self) private var dataProvider
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var composer: String
    @State private var keySignature: String
    @State private var timeSignature: String
    @State private var tempoBPM: String
    @State private var form: String
    @State private var feel: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    let pieceID: UUID

    init(piece: Piece) {
        self.pieceID = piece.id
        _title = State(initialValue: piece.title)
        _composer = State(initialValue: piece.composer ?? "")
        _keySignature = State(initialValue: piece.keySignature ?? "")
        _timeSignature = State(initialValue: piece.timeSignature ?? "")
        _tempoBPM = State(initialValue: piece.tempoBPM.map { String(Int($0)) } ?? "")
        _form = State(initialValue: piece.form ?? "")
        _feel = State(initialValue: piece.feel ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("General") {
                    TextField("Title", text: $title)
                    TextField("Composer", text: $composer)
                }

                SwiftUI.Section("Musical Details") {
                    TextField("Key Signature", text: $keySignature)
                    TextField("Time Signature", text: $timeSignature)
                    TextField("Tempo (BPM)", text: $tempoBPM)
                        .keyboardType(.numberPad)
                    TextField("Form", text: $form)
                    TextField("Feel", text: $feel)
                }

                if let error = errorMessage {
                    SwiftUI.Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Piece")
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
                let update = PieceUpdate(
                    title: title,
                    composer: composer.isEmpty ? nil : composer,
                    key_signature: keySignature.isEmpty ? nil : keySignature,
                    time_signature: timeSignature.isEmpty ? nil : timeSignature,
                    tempo_bpm: Double(tempoBPM),
                    feel: feel.isEmpty ? nil : feel,
                    form: form.isEmpty ? nil : form
                )
                try await updatePiece(id: pieceID, update: update)
                await dataProvider.loadAll()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
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

// MARK: - Section Row View

struct SectionRowView: View {
    let section: Section
    let depth: Int
    var onDelete: ((UUID) -> Void)?
    var onSeek: ((Double) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                // Section type badge
                Text(section.sectionType.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(sectionColor.opacity(0.15))
                    .foregroundStyle(sectionColor)
                    .clipShape(Capsule())

                // Label
                if let label = section.label, !label.isEmpty {
                    Text(label)
                        .font(.subheadline.weight(.medium))
                }

                Spacer()

                // Time range (tap to seek)
                if let start = section.startTimeMs {
                    Button {
                        let seekMs = max(0, start - 2000)
                        onSeek?(seekMs)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle")
                                .font(.caption)
                            Text(timeString(start) + (section.endTimeMs.map { " – " + timeString($0) } ?? ""))
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Children (indented)
            if !section.children.isEmpty {
                ForEach(section.children) { child in
                    SectionRowView(section: child, depth: depth + 1, onDelete: onDelete, onSeek: onSeek)
                        .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .padding(.leading, CGFloat(depth) * 16)
        .background(depth == 0 ? AnyShapeStyle(.fill.quaternary) : AnyShapeStyle(.clear))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            if onDelete != nil {
                Button(role: .destructive) {
                    onDelete?(section.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func timeString(_ ms: Double) -> String {
        let totalSeconds = Int(ms / 1000)
        let min = totalSeconds / 60
        let sec = totalSeconds % 60
        return String(format: "%d:%02d", min, sec)
    }

    private var sectionColor: Color {
        switch section.sectionType {
        case .intro, .outro: .blue
        case .verse: .green
        case .chorus: .orange
        case .bridge, .transition: .purple
        case .solo: .red
        case .preChorus: .yellow
        case .interlude: .teal
        case .exposition, .development, .recapitulation: .indigo
        case .coda: .mint
        case .theme, .variation: .cyan
        case .scene: .pink
        case .other: .secondary
        }
    }
}

// MARK: - Piece Status Row

struct PieceStatusRow: View {
    let piece: Piece
    @Environment(DataProvider.self) private var dataProvider

    private struct StatusItem {
        let label: String
        let icon: String
        let color: Color
        let isOn: Bool
        let keyPath: WritableKeyPath<Piece, Bool>
    }

    private var items: [StatusItem] {
        [
            StatusItem(label: "Listened", icon: "ear", color: .blue, isOn: piece.listened, keyPath: \.listened),
            StatusItem(label: "Score", icon: "book", color: .orange, isOn: piece.scoreRead, keyPath: \.scoreRead),
            StatusItem(label: "Transcribed", icon: "list.clipboard", color: .green, isOn: piece.transcribed, keyPath: \.transcribed),
            StatusItem(label: "Analyzed", icon: "chart.bar.doc.horizontal", color: .purple, isOn: piece.analyzed, keyPath: \.analyzed),
            StatusItem(label: "Played", icon: "guitars", color: .red, isOn: piece.played, keyPath: \.played),
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.label) { item in
                Button {
                    toggle(item.keyPath)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .symbolVariant(item.isOn ? .fill : .none)
                            .font(.title3)
                            .foregroundStyle(item.isOn ? item.color : .secondary)
                            .frame(width: 32, height: 32)
                        Text(item.label)
                            .font(.system(size: 9))
                            .foregroundStyle(item.isOn ? .primary : .tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .background(.fill.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func toggle(_ keyPath: WritableKeyPath<Piece, Bool>) {
        var updated = piece
        updated[keyPath: keyPath].toggle()
        Task {
            try? await dataProvider.savePiece(updated)
        }
    }
}

// MARK: - Status Filter Bar

struct StatusFilterBar: View {
    @Environment(DataProvider.self) private var dataProvider

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PieceStatusFilter.allCases, id: \.self) { filter in
                let isActive = dataProvider.activeFilters.contains(filter)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isActive {
                            dataProvider.activeFilters.remove(filter)
                        } else {
                            dataProvider.activeFilters.insert(filter)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: filter.icon)
                            .font(.body)
                        if isActive {
                            Text(filter.label)
                                .font(.caption.weight(.medium))
                        }
                    }
                    .padding(.horizontal, isActive ? 12 : 10)
                    .padding(.vertical, 8)
                    .background(isActive ? AnyShapeStyle(filter.color.opacity(0.15)) : AnyShapeStyle(.fill.quaternary))
                    .foregroundStyle(isActive ? filter.color : .secondary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct StatusFilterToolbar: ToolbarContent {
    @Environment(DataProvider.self) private var dataProvider
    @Binding var showingFilters: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                withAnimation { showingFilters.toggle() }
            } label: {
                Image(systemName: dataProvider.isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .foregroundStyle(dataProvider.isFiltering ? Color.accentColor : .secondary)
            }
        }
    }
}
