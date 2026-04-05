import Foundation

enum InstrumentFamily: String, Codable {
    case strings
    case woodwinds
    case brass
    case percussion
    case keyboard
    case guitar
    case other
}

struct Instrument: Identifiable, Hashable, Codable {
    let id: UUID
    
    var name: String
    var family: InstrumentFamily
    var transposition: String
    var rangeLow: String?
    var rangeHigh: String?
    var aliases: [String]
}
