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
    
    //var parts: [Part]?
    //var sections: [Section]?
    var files: [File]?

}
