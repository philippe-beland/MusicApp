import Foundation
import MusicKit

class Album: ObservableObject {
    let id: UUID
    let title: String
    let artist: Artist
    let genre: String
    let releaseDate: String
    let appleMusicID: String?
    var songs: [Song] = []

    @Published var appleMusicItem: MusicKit.Album?

    init(id: UUID = UUID(), title: String, artist: Artist, genre: String, appleMusicID: String? = nil, releaseDate: String, songs: [Song] = []) {
        self.id = id
        self.title = title
        self.artist = artist
        self.genre = genre
        self.appleMusicID = appleMusicID
        self.releaseDate = releaseDate
        self.songs = songs
    }

    @MainActor
    func fetchAppleMusicItem() async {
        guard let appleMusicID else { return }
        var request = MusicCatalogResourceRequest<MusicKit.Album>(matching: \.id, equalTo: MusicItemID(rawValue: appleMusicID))
        request.limit = 1
        do {
            let response = try await request.response()
            self.appleMusicItem = response.items.first
        } catch {
            print("Failed to fetch album: \(error)")
        }
        
        for song in songs {
            await song.fetchAppleMusicItem()
        }
    }
    
    static let example = Album(
        title: "Kill 'Em All",
        artist: Artist(name: "Metallica", genre: "Metal"),
        genre: "Thrash Metal",
        appleMusicID: "579146130", 
        releaseDate: "1983-03-30",
        songs: [
            Song(number: 1, title: "Hit The Lights", appleMusicID: "579146160"),
            Song(number: 2, title: "The Four Horsemen", appleMusicID: "579146161"),
            Song(number: 3, title: "Motorbreath", appleMusicID: "579146162"),
            Song(number: 4, title: "Jump in the Fire", appleMusicID: "579146162")
        ]
        
    )
}
