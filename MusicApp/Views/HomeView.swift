//
//  HomeView.swift
//  MusicApp
//
//  Created by Philippe Beland on 2025-07-08.
//

import SwiftUI
import MusicKit

struct HomeView: View {
    @State private var albums: MusicItemCollection<Album> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Example: Recently Played Section
                    AlbumListView(title: "Récemment écoutés", albums: albums)
                    
                    // Recently Analyzed Section
                    AlbumListView(title: "Récemment analysés", albums: albums)
                    
                    // Most Opened Section
                    AlbumListView(title: "Plus souvent ouvert", albums: albums)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            let status = await MusicAuthorization.request()
            if status == .authorized {
                await fetchAlbums()
            } else {
                albums = []
            }
        }
    }

    func fetchAlbums() async {
        let request = MusicCatalogSearchRequest(term: "John Williams", types: [MusicKit.Album.self])
        do {
            let response = try await request.response()
            // Sort albums by release date in ascending order
            let sortedAlbums = response.albums.sorted { album1, album2 in
                guard let date1 = album1.releaseDate, let date2 = album2.releaseDate else {
                    // If one album has no release date, put it at the end
                    return album1.releaseDate != nil
                }
                return date1 < date2
            }
            albums = MusicItemCollection(sortedAlbums)
        } catch {
            print("Error in requesting for search: \(error)")
        }
    }
}

struct AlbumCard: View {
    let album: Album
    let size: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let artwork = album.artwork {
                ArtworkImage(artwork, height: size)
            }
            
            Text(album.title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
            Text(album.artistName)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: size)
    }
}

struct AlbumListView: View {
    var title: String
    var albums: MusicItemCollection<Album>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(albums, id: \.id) { album in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            AlbumCard(album: album, size: 160)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        }
    }

#Preview {
    HomeView()
}
