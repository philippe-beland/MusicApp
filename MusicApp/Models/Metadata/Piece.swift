import Foundation

struct Piece: Identifiable, Hashable, Codable {
    let id: UUID
    var Work: Work?
    
    var title: String
    var pieceNumber: Int?
    var language: String?
    var composer: String?
    var lyricist: String?
    var librettist: String?
    var copyright: String?
    var contributors: [String]?
    
    var keySignature: String?
    var modalFlavor: String?
    var timeSignature: String?
    var tempoBPM: Double?
    var durationMS: Int?
    
    var difficultyLevel: String?
    var feel: String?
    var genre: Genre?
    var form: String?
    
    var sceneDescription: String?
    var timecode: String?

    // Status flags
    var listened: Bool = false
    var scoreRead: Bool = false
    var transcribed: Bool = false
    var analyzed: Bool = false
    var played: Bool = false

    //var parts: [Part]?
    var sections: [Section]?
    var files: [File]?

}
