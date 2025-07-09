//
//  ArtistDetailView.swift
//  MusicApp
//
//  Created by Philippe Beland on 2025-07-08.
//

import SwiftUI
import MusicKit

struct ArtistDetailView: View {
    let artist: Artist
    @State private var albums: [Album] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var isFavorite = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Artist image and favorite
                ZStack(alignment: .topTrailing) {
                    ArtistArtwork(artwork: artist.artwork, size: 220)
                        .frame(maxWidth: .infinity)
                    Button(action: { isFavorite.toggle() }) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(.yellow)
                            .padding()
                    }
                }
                .padding(.top)

                // Albums section
                Text("Albums")
                    .font(.title2)
                    .bold()
                    .padding(.leading, 16)

                if isLoading {
                    ProgressView("Chargement des albums…")
                        .padding()
                } else if let error = error {
                    VStack(alignment: .leading) {
                        Text("Erreur: \(error.localizedDescription)")
                        Button("Réessayer") {
                            Task { await fetchAlbums() }
                        }
                    }
                    .padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(albums, id: \.id) { album in
                                NavigationLink(destination: AlbumDetailView(album: album)) {
                                    AlbumCard(album: album, size: 140)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                // Similar artists section (placeholder)
                Text("Artistes similaires ?")
                    .font(.headline)
                    .padding(.top, 32)
                    .padding(.leading, 16)

                Spacer()
            }
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchAlbums()
        }
    }

    // Fetch albums for the artist, filter and sort
    func fetchAlbums() async {
        isLoading = true
        error = nil
        do {
            let request = MusicCatalogResourceRequest<Album>(matching: \.artist, equalTo: artist)
            let response = try await request.response()
            let filtered = response.items.filter { album in
                // Exclude compilations, live, singles, etc.
                let lower = album.title.lowercased()
                return !lower.contains("compil") && !lower.contains("live") && !lower.contains("single")
            }
            let sorted = filtered.sorted {
                ($0.releaseDate ?? .distantFuture) < ($1.releaseDate ?? .distantFuture)
            }
            albums = sorted
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

// Helper for artist artwork
struct ArtistArtwork: View {
    let artwork: Artwork?
    let size: CGFloat

    var body: some View {
        if let artwork = artwork {
            AsyncImage(url: artwork.url(width: Int(size), height: Int(size))) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: size, height: size)
            .cornerRadius(16)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)
        }
    }
}

#Preview {
    ArtistDetailView(artist: Artist(id: "1", name: "Artist Name", artwork: nil))
}
