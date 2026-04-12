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

    /// Extract instrument name from the filename (last segment after splitting by "-").
    var instrumentName: String? {
        guard let url = storageURL ?? filePath.flatMap({ URL(string: $0) }) else { return nil }
        let filename = url.deletingPathExtension().lastPathComponent
        let parts = filename.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count > 1 else { return nil }
        return parts.last
    }
}
