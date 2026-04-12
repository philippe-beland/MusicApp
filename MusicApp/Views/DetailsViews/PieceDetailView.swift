import SwiftUI

struct PieceDetailView: View {
    let piece: Piece
    let work: Work
    @State private var showingEdit = false

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            PieceEditView(piece: piece)
        }
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
                Section("General") {
                    TextField("Title", text: $title)
                    TextField("Composer", text: $composer)
                }

                Section("Musical Details") {
                    TextField("Key Signature", text: $keySignature)
                    TextField("Time Signature", text: $timeSignature)
                    TextField("Tempo (BPM)", text: $tempoBPM)
                        .keyboardType(.numberPad)
                    TextField("Form", text: $form)
                    TextField("Feel", text: $feel)
                }

                if let error = errorMessage {
                    Section {
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


