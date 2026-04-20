import Foundation

enum SectionType: String, Codable, CaseIterable {
    case intro
    case verse
    case preChorus = "pre_chorus"
    case chorus
    case bridge
    case solo
    case outro
    case interlude
    case exposition
    case development
    case recapitulation
    case coda
    case theme
    case variation
    case scene
    case transition
    case other

    var displayName: String {
        switch self {
        case .preChorus: return "Pre-Chorus"
        default:
            return rawValue.capitalized
        }
    }
}

struct Section: Identifiable, Hashable, Codable {
    let id: UUID
    var pieceId: UUID?
    var parentSectionId: UUID?

    var label: String?
    var sectionType: SectionType

    var startMeasure: Int?
    var endMeasure: Int?
    var startTimeMs: Double?
    var endTimeMs: Double?

    var keyContext: String?
    var timeSignature: String?
    var tempoBPM: Double?

    var orderIndex: Int?
    var notes: String?

    var children: [Section] = []
}
