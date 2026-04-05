import SwiftUI

struct SearchView: View {
    @Environment(DataProvider.self) private var dataProvider
    @State private var searchText = ""

    private var filteredWorks: [Work] {
        guard !searchText.isEmpty else { return dataProvider.works }
        let query = searchText.lowercased()
        return dataProvider.works.filter {
            $0.title.lowercased().contains(query) ||
            $0.artist.name.lowercased().contains(query) ||
            $0.genre.rawValue.lowercased().contains(query)
        }
    }

    private var filteredArtists: [Artist] {
        guard !searchText.isEmpty else { return dataProvider.artists }
        let query = searchText.lowercased()
        return dataProvider.artists.filter {
            $0.name.lowercased().contains(query) ||
            $0.genres.rawValue.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !filteredArtists.isEmpty {
                    Section("Artists") {
                        ForEach(filteredArtists) { artist in
                            NavigationLink(destination: ArtistDetailView(artist: artist, works: dataProvider.works.filter { $0.artist.id == artist.id })) {
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

                if filteredWorks.isEmpty && filteredArtists.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Works, artists, genres...")
        }
    }
}

#Preview {
    SearchView()
        .environment(DataProvider())
}
