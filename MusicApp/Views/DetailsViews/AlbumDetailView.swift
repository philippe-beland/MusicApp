import SwiftUI
import MusicKit

struct AlbumDetailView: View {
    let album: Album
    @State private var tracks: MusicItemCollection<Track>?
    @State private var isLoadingTracks = false
    @State private var trackError: Error?
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AlbumHeader(album: album)
                    ActionButtons(tracks: tracks)
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
            VStack {
                Spacer()
                MusicPlayerControls()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    private func loadTracks() async {
        isLoadingTracks = true
        trackError = nil
        
        do {
            // Fetch the full album with tracks
            var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: album.id)
            request.properties = [.tracks]
            let response = try await request.response()
            
            if let fullAlbum = response.items.first {
                tracks = fullAlbum.tracks
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
            if let artwork = album.artwork {
                ArtworkImage(artwork, height: 200)
            }
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
    var tracks: MusicItemCollection<Track>?
    
    var body: some View {
        // Action buttons
        HStack(spacing: 20) {
            Button(action: { playEntireAlbum() }) {
                Text("Lecture")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
            Button(action: { sampleEntireAlbum() }) {
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
    
    func playEntireAlbum() {
        guard let tracks = tracks else { return }
        
        let tracksToPlay = Array(tracks)
        
        Task {
            ApplicationMusicPlayer.shared.queue = .init(for: tracksToPlay)
            try? await ApplicationMusicPlayer.shared.play()
        }
    }
    
    func sampleEntireAlbum() {
        guard let tracks = tracks else { return }
        let tracksArray = Array(tracks)
        
        Task {
            for track in tracksArray {
                // Set the queue to just this track
                ApplicationMusicPlayer.shared.queue = .init(for: [track])
                
                // Get the track duration
                let duration = track.duration ?? 60
                let maxStart = max(0, duration - 30)
                let randomStart = maxStart > 0 ? Double.random(in: 0...maxStart) : 0

                // Seek to the random start time
                ApplicationMusicPlayer.shared.playbackTime = randomStart
                try? await ApplicationMusicPlayer.shared.play()

                // Wait for 30 seconds or until playback ends
                let playTask = Task {
                    try? await Task.sleep(for: .seconds(30))
                }

                // Also observe if the track ends before 30 seconds
                while ApplicationMusicPlayer.shared.state.playbackStatus == .playing &&
                    ApplicationMusicPlayer.shared.playbackTime < (randomStart + 30) &&
                    ApplicationMusicPlayer.shared.playbackTime < duration {
                    try? await Task.sleep(for: .milliseconds(500))
                    }
                    playTask.cancel()
            }
            // Optionally stop plaback at the end
            ApplicationMusicPlayer.shared.stop()
            }
        }
    }

struct TrackList: View {
    let tracks: MusicItemCollection<Track>
    @State private var selectedTrack: Track? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                TrackRow(track: track, index: index, tracks: Array(tracks)) {
                    selectedTrack = track
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedTrack != nil },
            set: { if !$0 { selectedTrack = nil } }
        )) {
            if let track = selectedTrack {
                TrackDetailView(track: track)
            }
        }
    }
}

struct TrackRow: View {
    var track: Track
    var index: Int
    var tracks: [Track]
    var onShowDetail: () -> Void
    
    var body: some View {
        HStack {
            Text("\(index + 1). \(track.title)")
                .font(.body)
            Spacer()
            Text(formatDuration(track.duration))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button(action: onShowDetail) {
                Text("…")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            playFromThisTrack()
        }
    }
    
    func playFromThisTrack() {
        let tracksToPlay = Array(tracks[index...])
        Task {
            ApplicationMusicPlayer.shared.queue = .init(for: tracksToPlay)
            try? await ApplicationMusicPlayer.shared.play()
        }
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

