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

    /// Section types relevant to a given genre. Shared types (intro, outro, etc.) appear in all.
    static func types(for genre: Genre) -> [SectionType] {
        let shared: [SectionType] = [.intro, .outro, .interlude, .transition, .solo, .other]

        switch genre {
        case .classical:
            return [.exposition, .development, .recapitulation, .coda, .theme, .variation, .scene] + shared
        case .filmScore:
            return [.theme, .variation, .scene, .coda] + shared
        case .jazz:
            return [.theme, .chorus, .verse, .bridge, .coda] + shared
        case .rock, .pop, .electronic:
            return [.verse, .preChorus, .chorus, .bridge] + shared
        case .other:
            return allCases
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
