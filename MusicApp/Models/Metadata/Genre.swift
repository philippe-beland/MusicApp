import SwiftUI

enum Genre: String, Codable, CaseIterable {
    case classical
    case filmScore = "film_score"
    case jazz
    case rock
    case pop
    case electronic
    case other

    var displayName: String {
        switch self {
        case .classical: "Classical"
        case .filmScore: "Film Score"
        case .jazz: "Jazz"
        case .rock: "Rock"
        case .pop: "Pop"
        case .electronic: "Electronic"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .classical: "music.note.list"
        case .filmScore: "film"
        case .jazz: "music.quarternote.3"
        case .rock: "guitars"
        case .pop: "star.fill"
        case .electronic: "waveform"
        case .other: "music.note"
        }
    }

    var color: Color {
        switch self {
        case .classical: .indigo
        case .filmScore: .orange
        case .jazz: .blue
        case .rock: .gray
        case .pop: .pink
        case .electronic: .cyan
        case .other: .teal
        }
    }
}
