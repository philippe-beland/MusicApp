import Foundation

enum SourceType: String, Codable {
    case musicxml
    case musescore
    case guitarPro = "guitar_pro"
    case midi
    case audio
    case pdfScore = "pdf_score"
    case video
}

struct File: Identifiable, Hashable, Codable {
    let id: UUID
    var pieceId: UUID?

    var sourceType: SourceType
    var filePath: String?
    var storageURL: URL?
    var isPrimary: Bool = false
}
