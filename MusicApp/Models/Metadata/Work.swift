import Foundation

enum WorkType: String, CaseIterable, Codable {
    case album
    case symphony
    case suite
    case soundtrack
    case opera
    case other
}

struct Work: Identifiable, Hashable, Codable {
    let id: UUID
    var artist: Artist
    
    // Metadata
    var title: String
    var workType: WorkType
    var genre: Genre
    var country: String?
    var releaseDate: Date?
    var artworkURL: URL?
    
    // Classical Metadata
    var opus: String?
    var premiereDate: Date?
    var premiereLocation: String?
    var catalogue: String?
    
    // Film Metadata
    var filmTitle: String?
    var director: String?
    var awards: [String]
    
    // Additional Metadata
    var label: String?
    var producer: String?
    var recordingStudio: String?
    
    var notes: String?
    

    var pieces: [Piece] = []
}
