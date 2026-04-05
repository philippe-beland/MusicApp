import Foundation

struct Part: Identifiable {
    let id: UUID = UUID()
    
    var piece: Piece?
    var name: String?
    var instrument: Instrument?
    var staffCount: Int? = 1
    var musicXMLPartId: String?
    var orderIndex: Int?
}

