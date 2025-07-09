import SwiftUI
import MusicKit

struct AlbumDetailView: View {
    let album: Album
    @State private var tracks: MusicItemCollection<Track>?
    @State private var isLoadingTracks = false
    @State private var trackError: Error?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AlbumHeader(album: album)
                ActionButtons()
                Divider()
                
                // Tracks section
                if isLoadingTracks {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Chargement des pistes...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                } else if let error = trackError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Erreur lors du chargement des pistes")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Réessayer") {
                            Task {
                                await loadTracks()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if let tracks = tracks {
                    TrackList(tracks: tracks)
                } else {
                    Text("No errors but no tracks either...")
                }
            }
            .padding()
        }
        .navigationTitle("Détail Album")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTracks()
        }
    }
    
    private func loadTracks() async {
        isLoadingTracks = true
        trackError = nil
        
        do {
            // Fetch the full album with tracks
            let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: album.id)
            let response = try await request.response()
            
            if let fullAlbum = response.items.first {
                let detailedAlbum = try await fullAlbum.with(.tracks)
                tracks = detailedAlbum.tracks
            } else {
                trackError = NSError(domain: "AlbumDetailView", code: 404, userInfo: [NSLocalizedDescriptionKey: "Album non trouvé"])
            }
        } catch {
            trackError = error
        }
        
        isLoadingTracks = false
    }
}

struct AlbumHeader: View {
    let album: Album
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AlbumCover(album: album)
            AlbumInfos(album: album)

        }
    }
}

struct AlbumInfos: View {
    var album: Album
    
    var body: some View {
        // Title & artist
        Text(album.title)
            .font(.title)
            .fontWeight(.bold)
        Text(album.artistName)
            .font(.title3)
            .foregroundColor(.secondary)
        Text("Genre: \(album.genreNames.joined(separator: ", ")) | Date: \(String(describing: album.releaseDate))")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
}

struct AlbumCover: View {
    var album: Album
    
    var body: some View {
        HStack(alignment: .top) {
            // Album artwork
            AlbumArtwork(artwork: album.artwork, size: 200)
            Spacer()
            
            // Favorite star
            Button(action: {}) {
                Image(systemName: "star")
                    .font(.title)
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct ActionButtons: View {
    var body: some View {
        // Action buttons
        HStack(spacing: 20) {
            Button(action: {}) {
                Text("Lecture")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
            Button(action: {}) {
                Text("Survol")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct TrackList: View {
    let tracks: MusicItemCollection<Track>
    
    var body: some View {
        // Track list
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                TrackRow(track: track, index: index)
            }
        }
    }
}

struct TrackRow: View {
    var track: Track
    var index: Int
    
    var body: some View {
        NavigationLink(destination: TrackDetailView(track: track)) {
            HStack {
                Text("\(index + 1). \(track.title)")
                    .font(.body)
                Spacer()
                Text(formatDuration(track.duration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("…")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .foregroundColor(.blue)
            }
        }
        .buttonStyle(PlainButtonStyle())
        Divider()
    }
    
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "0:00" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

//#Preview {
//    let id = MusicItemID("1506574436")
//    let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: id)
//    let response = try await request.response()
//    
//    guard let album = response.items.first else { }
//    AlbumDetailView(album: album)
//}

