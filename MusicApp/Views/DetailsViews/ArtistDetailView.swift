import SwiftUI

struct ArtistDetailView: View {
    let artist: Artist
    let works: [Work]
    @State private var showingEdit = false

    private var sortedWorks: [Work] {
        works.sorted {
            ($0.releaseDate ?? .distantFuture) < ($1.releaseDate ?? .distantFuture)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Artist header
                VStack(spacing: 12) {
                    ArtistAvatarPlaceholder(artist: artist, size: 120)

                    Text(artist.name)
                        .font(.title.bold())

                    HStack(spacing: 12) {
                        Label(artist.type.rawValue.capitalized, systemImage: "person")
                        if let country = artist.country {
                            Label(country, systemImage: "globe")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)

                // Notes
                if let notes = artist.notes {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                // Members
                if !artist.members.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Members")
                            .font(.title3.bold())
                        ForEach(artist.members, id: \.self) { member in
                            Label(member, systemImage: "person.fill")
                                .font(.body)
                        }
                    }
                    .padding(.horizontal)
                }

                // Works by this artist (sorted by release date)
                if !works.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Works")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        ForEach(sortedWorks) { work in
                            NavigationLink(destination: WorkDetailView(work: work)) {
                                ArtistWorkRow(work: work)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom)
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            ArtistEditView(artist: artist)
        }
    }
}

// MARK: - Artist Work Row (with release date)

struct ArtistWorkRow: View {
    let work: Work

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            WorkArtworkPlaceholder(work: work, height: 56)
                .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(work.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(work.workType.rawValue.capitalized)
                    if let date = work.releaseDate {
                        Text("·")
                        Text(Self.yearFormatter.string(from: date))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Artist Edit View

struct ArtistEditView: View {
    @Environment(DataProvider.self) private var dataProvider
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var type: ArtistType
    @State private var genre: Genre
    @State private var country: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    let artistID: UUID

    init(artist: Artist) {
        self.artistID = artist.id
        _name = State(initialValue: artist.name)
        _type = State(initialValue: artist.type)
        _genre = State(initialValue: artist.genres)
        _country = State(initialValue: artist.country ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(ArtistType.allCases, id: \.self) { t in
                            Text(t.rawValue.capitalized).tag(t)
                        }
                    }
                    Picker("Genre", selection: $genre) {
                        ForEach(Genre.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                    TextField("Country", text: $country)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                var updated = Artist(
                    id: artistID, name: name, sortName: name,
                    type: type, aliases: nil, genres: genre,
                    country: country.isEmpty ? nil : country,
                    beginDate: nil, endDate: nil, members: [], notes: nil
                )
                _ = updated
                try await dataProvider.saveArtist(Artist(
                    id: artistID, name: name, sortName: name,
                    type: type, aliases: nil, genres: genre,
                    country: country.isEmpty ? nil : country,
                    beginDate: nil, endDate: nil, members: [], notes: nil
                ))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}


