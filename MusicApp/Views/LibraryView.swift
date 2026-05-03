import SwiftUI

struct LibraryView: View {
    @Environment(DataProvider.self) private var dataProvider
    @State private var searchText = ""
    @State private var showingFilters = false

    private var isSearching: Bool { !searchText.isEmpty }

    private var filteredArtists: [Artist] {
        let query = searchText.lowercased()
        let baseArtists = dataProvider.filteredArtists(from: dataProvider.artists, works: dataProvider.filteredWorks)
        return baseArtists.filter {
            $0.name.lowercased().contains(query) ||
            $0.genres.rawValue.lowercased().contains(query)
        }
    }

    private var filteredWorks: [Work] {
        let query = searchText.lowercased()
        return dataProvider.filteredWorks.filter {
            $0.title.lowercased().contains(query) ||
            $0.artist.name.lowercased().contains(query) ||
            $0.genre.rawValue.lowercased().contains(query)
        }
    }

    private var filteredPieces: [(piece: Piece, work: Work)] {
        let query = searchText.lowercased()
        return dataProvider.filteredWorks.flatMap { work in
            work.pieces
                .filter { $0.title.lowercased().contains(query) }
                .map { (piece: $0, work: work) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isSearching {
                    List {
                        if !filteredArtists.isEmpty {
                            SwiftUI.Section("Artists") {
                                ForEach(filteredArtists) { artist in
                                    NavigationLink(destination: ArtistDetailView(
                                        artist: artist,
                                        works: dataProvider.works.filter { $0.artist.id == artist.id }
                                    )) {
                                        ArtistListRow(artist: artist)
                                    }
                                }
                            }
                        }

                        if !filteredWorks.isEmpty {
                            SwiftUI.Section("Works") {
                                ForEach(filteredWorks) { work in
                                    NavigationLink(destination: WorkDetailView(work: work)) {
                                        WorkListRow(work: work)
                                    }
                                }
                            }
                        }

                        if !filteredPieces.isEmpty {
                            SwiftUI.Section("Pieces") {
                                ForEach(filteredPieces, id: \.piece.id) { result in
                                    NavigationLink(destination: PieceDetailView(
                                        piece: result.piece,
                                        work: result.work
                                    )) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.piece.title)
                                                .font(.body.weight(.medium))
                                            Text("\(result.work.title) · \(result.work.artist.name)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }

                        if filteredArtists.isEmpty && filteredWorks.isEmpty && filteredPieces.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        }
                    }
                    .listStyle(.insetGrouped)
                } else if dataProvider.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            if showingFilters {
                                StatusFilterBar()
                                    .padding(.horizontal)
                            }

                            // Recently Listened
                            if !dataProvider.filteredWorks.isEmpty {
                                WorkCarousel(title: "Recently Listened", works: dataProvider.filteredWorks)
                            }

                            // Genre browsing
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Browse by Genre")
                                    .font(.title3.bold())
                                    .padding(.horizontal)

                                GenreGridView(
                                    artists: dataProvider.filteredArtists(from: dataProvider.artists, works: dataProvider.filteredWorks),
                                    works: dataProvider.filteredWorks
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Works, artists, genres...")
            .toolbar {
                StatusFilterToolbar(showingFilters: $showingFilters)
            }
        }
    }
}

// MARK: - Genre Grid

struct GenreGridView: View {
    let artists: [Artist]
    let works: [Work]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Genre.allCases, id: \.self) { genre in
                NavigationLink(destination: GenreArtistsView(
                    genre: genre,
                    artists: artists.filter { $0.genres == genre },
                    works: works.filter { $0.genre == genre }
                )) {
                    GenreTile(
                        genre: genre,
                        artworkURL: works.first(where: { $0.genre == genre && $0.artworkURL != nil })?.artworkURL
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct GenreTile: View {
    let genre: Genre
    let artworkURL: URL?

    var body: some View {
        HStack(spacing: 12) {
            // Small artwork or icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(genre.color.gradient)

                if let url = artworkURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Image(systemName: genre.icon)
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: genre.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 56, height: 56)

            Text(genre.displayName)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(genre.color.opacity(0.30))
                )
        }
    }
}

// MARK: - Genre Artists View

struct GenreArtistsView: View {
    let genre: Genre
    let artists: [Artist]
    let works: [Work]
    @Environment(DataProvider.self) private var dataProvider
    @State private var showingNewArtist = false
    @State private var showingFilters = false

    private var displayedArtists: [Artist] {
        dataProvider.filteredArtists(from: artists, works: displayedWorks)
    }

    private var displayedWorks: [Work] {
        guard dataProvider.isFiltering else { return works }
        return works.compactMap { work in
            let kept = work.pieces.filter { dataProvider.piecePassesFilters($0) }
            guard !kept.isEmpty else { return nil }
            var filtered = work
            filtered.pieces = kept
            return filtered
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if showingFilters {
                StatusFilterBar()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

            List(displayedArtists) { artist in
                NavigationLink(destination: ArtistDetailView(
                    artist: artist,
                    works: displayedWorks.filter { $0.artist.id == artist.id }
                )) {
                    ArtistListRow(artist: artist)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(genre.displayName)
        .toolbar {
            StatusFilterToolbar(showingFilters: $showingFilters)
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewArtist = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewArtist) {
            NewArtistView(defaultGenre: genre)
        }
    }
}

// MARK: - New Artist View

struct NewArtistView: View {
    @Environment(DataProvider.self) private var dataProvider
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: ArtistType = .person
    @State private var genre: Genre
    @State private var country = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(defaultGenre: Genre = .other) {
        _genre = State(initialValue: defaultGenre)
    }

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("General") {
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
                    SwiftUI.Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    private func create() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await dataProvider.createArtist(
                    name: name,
                    type: type,
                    genre: genre,
                    country: country.isEmpty ? nil : country
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - Artist List Row

struct ArtistListRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 14) {
            ArtistAvatarPlaceholder(artist: artist, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.body.weight(.medium))
                Text(artist.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Work List Row

struct WorkListRow: View {
    let work: Work

    var body: some View {
        HStack(spacing: 14) {
            WorkArtworkPlaceholder(work: work, height: 56)
                .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(work.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(work.artist.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(work.workType.rawValue.capitalized)
                    Text("·")
                    Text(work.genre.displayName)
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Artist Avatar

struct ArtistAvatarPlaceholder: View {
    let artist: Artist
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(artist.genres.color.gradient)
            Text(String(artist.name.prefix(1)))
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    LibraryView()
        .environment(DataProvider())
}
