import Foundation

enum Genre: String, Codable {
    case classical
    case filmScore = "film_score"
    case jazz
    case rock
    case metal
    case pop
    case electronic
    case other
}
