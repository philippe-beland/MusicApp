import SwiftUI

struct LibraryView: View {
    @Environment(DataProvider.self) private var dataProvider
    @State private var searchText = ""

    private var isSearching: Bool { !searchText.isEmpty }

    private var filteredArtists: [Artist] {
        let query = searchText.lowercased()
        return dataProvider.artists.filter {
            $0.name.lowercased().contains(query) ||
            $0.genres.rawValue.lowercased().contains(query)
        }
    }

    private var filteredWorks: [Work] {
        let query = searchText.lowercased()
        return dataProvider.works.filter {
            $0.title.lowercased().contains(query) ||
            $0.artist.name.lowercased().contains(query) ||
            $0.genre.rawValue.lowercased().contains(query)
        }
    }

    private var filteredPieces: [(piece: Piece, work: Work)] {
        let query = searchText.lowercased()
        return dataProvider.works.flatMap { work in
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
                            Section("Artists") {
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
                            Section("Works") {
                                ForEach(filteredWorks) { work in
                                    NavigationLink(destination: WorkDetailView(work: work)) {
                                        WorkListRow(work: work)
                                    }
                                }
                            }
                        }

                        if !filteredPieces.isEmpty {
                            Section("Pieces") {
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
                            // Recently Listened
                            if !dataProvider.works.isEmpty {
                                WorkCarousel(title: "Recently Listened", works: dataProvider.works)
                            }

                            // Genre browsing
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Browse by Genre")
                                    .font(.title3.bold())
                                    .padding(.horizontal)

                                GenreGridView(
                                    artists: dataProvider.artists,
                                    works: dataProvider.works
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

    var body: some View {
        List(artists) { artist in
            NavigationLink(destination: ArtistDetailView(
                artist: artist,
                works: works.filter { $0.artist.id == artist.id }
            )) {
                ArtistListRow(artist: artist)
            }
        }
        .listStyle(.plain)
        .navigationTitle(genre.displayName)
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
