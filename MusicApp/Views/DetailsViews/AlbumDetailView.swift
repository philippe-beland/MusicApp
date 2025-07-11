import SwiftUI
import MusicKit

struct AlbumDetailView: View {
    let album: Album
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AlbumHeader(album: album)
                    ActionButtons(songs: album.songs)
                    Divider()
                    SongList(album: album)
                    
                }
                .padding()
            }
            .navigationTitle("Détail Album")
            .navigationBarTitleDisplayMode(.inline)
            VStack {
                Spacer()
                MusicPlayerControls()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
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
            Text(album.artist.name)
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Genre: \(album.genre) | Date: \(String(describing: album.releaseDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    struct AlbumCover: View {
        var album: Album
        
        var body: some View {
            HStack(alignment: .top) {
                // Album artwork
                if let artwork = album.appleMusicItem?.artwork {
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
        var songs: [Song]
        
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
            var songss: [MusicKit.Song] = []
            
            for song in songs {
                guard let appleSong = song.appleMusicItem else { continue }
                songss.append(appleSong)
            }
            
            let songsToPlay = MusicItemCollection(songss)
            
            Task {
                ApplicationMusicPlayer.shared.queue = .init(for: songsToPlay)
                try? await ApplicationMusicPlayer.shared.play()
            }
        }
        
        func sampleEntireAlbum() {
            var songsArray: [MusicKit.Song] = []
            
            for song in songs {
                guard let appleSong = song.appleMusicItem else { continue }
                songsArray.append(appleSong)
            }
            
            Task {
                for song in songsArray {
                    // Set the queue to just this song
                    ApplicationMusicPlayer.shared.queue = .init(for: [song])
                    
                    // Get the song duration
                    let duration = song.duration ?? 60
                    let maxStart = max(0, duration - 30)
                    let randomStart = maxStart > 0 ? Double.random(in: 0...maxStart) : 0
                    
                    // Seek to the random start time
                    ApplicationMusicPlayer.shared.playbackTime = randomStart
                    try? await ApplicationMusicPlayer.shared.play()
                    
                    // Wait for 30 seconds or until playback ends
                    let playTask = Task {
                        try? await Task.sleep(for: .seconds(30))
                    }
                    
                    // Also observe if the song ends before 30 seconds
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
}

struct SongList: View {
    let album: Album
    @State private var selectedSong: Song? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(album.songs.enumerated()), id: \.element.id) { index, song in
                SongRow(song: song, index: index, songs: album.songs) {
                    selectedSong = song
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedSong != nil },
            set: { if !$0 { selectedSong = nil } }
        )) {
            if let song = selectedSong {
                SongDetailView(song: song, album: album)
            }
        }
    }
}

struct SongRow: View {
    var song: Song
    var index: Int
    var songs: [Song]
    var onShowDetail: () -> Void
    
    var body: some View {
        HStack {
            Text("\(index + 1). \(song.title)")
                .font(.body)
            Spacer()
            Text(formatDuration(song.duration))
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
            playFromThisSong()
        }
    }
    
    func playFromThisSong() {
        var songsArray: [MusicKit.Song] = []
        
        for song in songs {
            guard let appleSong = song.appleMusicItem else { continue }
            songsArray.append(appleSong)
        }
        
        let songsToPlay = songsArray[index...]
        Task {
            ApplicationMusicPlayer.shared.queue = .init(for: songsToPlay)
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

