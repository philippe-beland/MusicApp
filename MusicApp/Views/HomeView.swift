//
//  HomeView.swift
//  MusicApp
//
//  Created by Philippe Beland on 2025-07-08.
//

import SwiftUI
import MusicKit

struct HomeView: View {
    @State private var albums: [Album] = []

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
        let album = Album.example
        await album.fetchAppleMusicItem()
        albums = [album]
    }
}

struct AlbumCard: View {
    let album: Album
    let size: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let artwork = album.appleMusicItem?.artwork {
                ArtworkImage(artwork, height: size)
            }
            
            Text(album.title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
            Text(album.artist.name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: size)
    }
}

struct AlbumListView: View {
    var title: String
    var albums: [Album]
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
