import Foundation
import MusicKit

struct Artist: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let genre: String
    let appleMusicItem: MusicKit.Artist? = nil
}
