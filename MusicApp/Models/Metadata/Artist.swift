import Foundation

enum ArtistType: String, Codable, CaseIterable {
    case person
    case ensemble
    case alias
}

struct Artist: Identifiable, Hashable, Codable {

    // MARK: - Identity
    var id: UUID

    // MARK: - Core Info
    var name: String
    var sortName: String
    var type: ArtistType
    var aliases: [String]?
    var genres: Genre
    var country: String?
    var beginDate: Date?
    var endDate: Date?
    var members: [String]
    var notes: String?

    // MARK: - Coding Keys (camelCase ↔ Supabase snake_case)
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortName       = "sort_name"
        case type
        case aliases
        case genres
        case country
        case beginDate      = "begin_date"
        case endDate        = "end_date"
        case members
        case notes
    }
}
