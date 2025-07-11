import Foundation
import MusicKit

class Song: ObservableObject {
    let id: UUID
    let number: Int
    let title: String
    //let album: Album
    let duration: TimeInterval?
    let appleMusicID: String?
    
    @Published var appleMusicItem: MusicKit.Song?
    
    init(id: UUID = UUID(), number: Int, title: String, duration: TimeInterval? = nil, appleMusicID: String? = nil) {
        self.id = id
        self.number = number
        self.title = title
        self.duration = duration
        self.appleMusicID = appleMusicID
    }
    
    @MainActor
    func fetchAppleMusicItem() async {
        guard let appleMusicID else { return }
        var request = MusicCatalogResourceRequest<MusicKit.Song>(matching: \.id, equalTo: MusicItemID(rawValue: appleMusicID))
        request.limit = 1
        do {
            let response = try await request.response()
            self.appleMusicItem = response.items.first
        } catch {
            print("Failed to fetch album: \(error)")
        }
    }
}
