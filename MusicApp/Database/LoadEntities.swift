import Foundation
import Supabase

// MARK: - Database Row DTOs (match SQL schema exactly)

struct ArtistRow: Codable, Sendable {
    let id: UUID
    let name: String
    let type: String?
    let genre: String?
    let birth_date: String?
    let death_date: String?
    let country: String?
    let members: [String]?
}

struct WorkRow: Codable, Sendable {
    let id: UUID
    let title: String
    let work_type: String?
    let artist: ArtistRow?
    let genre: String?
    let country: String?
    let release_date: String?
    let opus: String?
    let premiere_date: String?
    let premiere_location: String?
    let film_title: String?
    let director: String?
    let awards: [String]?
    let label: String?
    let producer: String?
    let recording_studio: String?
    let notes: String?
    let artwork_url: String?
}

struct PieceRow: Codable, Sendable {
    let id: UUID
    let work_id: UUID?
    let title: String?
    let piece_number: Int?
    let language: String?
    let composer: String?
    let librettist: String?
    let copyright: String?
    let key_signature: String?
    let modal_flavor: String?
    let time_signature: String?
    let tempo_bpm: Double?
    let duration_ms: Int?
    let difficulty_level: String?
    let feel: String?
    let genre: String?
    let form: String?
    let scene_description: String?
    let time_code: String?
    let listened: Bool?
    let score_read: Bool?
    let transcribed: Bool?
    let analyzed: Bool?
    let played: Bool?
}

struct FileRow: Codable, Sendable {
    let id: UUID
    let piece_id: UUID?
    let source_type: String
    let file_path: String?
    let storage_url: String?
    let is_primary: Bool?
}

struct SectionRow: Codable, Sendable {
    let id: UUID
    let piece_id: UUID?
    let parent_section_id: UUID?
    let label: String?
    let section_type: String?
    let start_measure: Int?
    let end_measure: Int?
    let start_time_ms: Int?
    let end_time_ms: Int?
    let key_context: String?
    let time_signature: String?
    let tempo_bpm: Double?
    let order_index: Int?
    let notes: String?
}

// MARK: - Row → Model Mapping

extension ArtistRow {
    func toArtist() -> Artist {
        Artist(
            id: id,
            name: name,
            sortName: name,
            type: ArtistType(rawValue: type ?? "") ?? .person,
            aliases: nil,
            genres: Genre(rawValue: genre ?? "") ?? .other,
            country: country,
            beginDate: nil,
            endDate: nil,
            members: members ?? [],
            notes: nil
        )
    }
}

extension FileRow {
    func toFile() -> File {
        File(
            id: id,
            pieceId: piece_id,
            sourceType: SourceType(rawValue: source_type) ?? .audio,
            filePath: file_path,
            storageURL: storage_url.flatMap { URL(string: $0) },
            isPrimary: is_primary ?? false
        )
    }
}

extension SectionRow {
    func toSection(children: [Section] = []) -> Section {
        Section(
            id: id,
            pieceId: piece_id,
            parentSectionId: parent_section_id,
            label: label,
            sectionType: SectionType(rawValue: section_type ?? "") ?? .other,
            startMeasure: start_measure,
            endMeasure: end_measure,
            startTimeMs: start_time_ms.map { Double($0) },
            endTimeMs: end_time_ms.map { Double($0) },
            keyContext: key_context,
            timeSignature: time_signature,
            tempoBPM: tempo_bpm,
            orderIndex: order_index,
            notes: notes,
            children: children
        )
    }
}

extension PieceRow {
    func toPiece(files: [File] = [], sections: [Section] = []) -> Piece {
        Piece(
            id: id,
            Work: nil,
            title: title ?? "Untitled",
            pieceNumber: piece_number,
            language: language,
            composer: composer,
            lyricist: nil,
            librettist: librettist,
            copyright: copyright,
            contributors: nil,
            keySignature: key_signature,
            modalFlavor: modal_flavor,
            timeSignature: time_signature,
            tempoBPM: tempo_bpm,
            durationMS: duration_ms,
            difficultyLevel: difficulty_level,
            feel: feel,
            genre: Genre(rawValue: genre ?? ""),
            form: form,
            sceneDescription: scene_description,
            timecode: time_code,
            listened: listened ?? false,
            scoreRead: score_read ?? false,
            transcribed: transcribed ?? false,
            analyzed: analyzed ?? false,
            played: played ?? false,
            sections: sections.isEmpty ? nil : sections,
            files: files.isEmpty ? nil : files
        )
    }
}

extension WorkRow {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    func toWork(pieces: [Piece]) -> Work {
        let mappedArtist = artist?.toArtist() ?? Artist(
            id: UUID(),
            name: "Unknown Artist",
            sortName: "Unknown",
            type: .person,
            aliases: nil,
            genres: .other,
            country: nil,
            beginDate: nil,
            endDate: nil,
            members: [],
            notes: nil
        )

        return Work(
            id: id,
            artist: mappedArtist,
            title: title,
            workType: WorkType(rawValue: work_type ?? "") ?? .other,
            genre: Genre(rawValue: genre ?? "") ?? .other,
            country: country,
            releaseDate: release_date.flatMap { Self.dateFormatter.date(from: $0) },
            artworkURL: artwork_url.flatMap { URL(string: $0) },
            opus: opus,
            premiereDate: nil,
            premiereLocation: premiere_location,
            catalogue: nil,
            filmTitle: film_title,
            director: director,
            awards: awards ?? [],
            label: label,
            producer: producer,
            recordingStudio: recording_studio,
            notes: notes,
            pieces: pieces
        )
    }
}

// MARK: - Fetch Functions

func fetchArtists() async throws -> [Artist] {
    let rows: [ArtistRow] = try await supabase
        .schema("music")
        .from("artist")
        .select()
        .execute()
        .value
    return rows.map { $0.toArtist() }
}

func fetchWorksWithPieces() async throws -> [Work] {
    // Fetch works with embedded artist
    let workRows: [WorkRow] = try await supabase
        .schema("music")
        .from("work")
        .select("*, artist(*)")
        .execute()
        .value

    // Fetch all pieces
    let pieceRows: [PieceRow] = try await supabase
        .schema("music")
        .from("piece")
        .select()
        .execute()
        .value

    // Fetch all files
    let fileRows: [FileRow] = try await supabase
        .schema("music")
        .from("file")
        .select()
        .execute()
        .value

    // Fetch all sections
    let sectionRows: [SectionRow] = try await supabase
        .schema("music")
        .from("section")
        .select()
        .execute()
        .value

    // Group files by piece_id
    let filesByPiece = Dictionary(grouping: fileRows, by: { $0.piece_id })

    // Build section trees grouped by piece_id
    let sectionsByPiece = buildSectionTrees(from: sectionRows)

    // Group pieces by work_id
    let piecesByWork = Dictionary(grouping: pieceRows, by: { $0.work_id })

    // Assemble works with their pieces, files, and sections
    return workRows.map { row in
        let pieces = (piecesByWork[row.id] ?? [])
            .sorted { ($0.piece_number ?? 0) < ($1.piece_number ?? 0) }
            .map { pieceRow in
                let files = (filesByPiece[pieceRow.id] ?? []).map { $0.toFile() }
                let sections = sectionsByPiece[pieceRow.id] ?? []
                return pieceRow.toPiece(files: files, sections: sections)
            }
        return row.toWork(pieces: pieces)
    }
}

// MARK: - Section Tree Builder

/// Groups section rows by piece_id and builds parent/child trees, returning top-level sections per piece.
private func buildSectionTrees(from rows: [SectionRow]) -> [UUID: [Section]] {
    let byPiece = Dictionary(grouping: rows, by: { $0.piece_id })
    var result: [UUID: [Section]] = [:]

    for (pieceId, pieceRows) in byPiece {
        guard let pieceId else { continue }

        // Group by parent_section_id
        let byParent = Dictionary(grouping: pieceRows, by: { $0.parent_section_id })

        // Recursive function to build children
        func buildChildren(parentId: UUID?) -> [Section] {
            (byParent[parentId] ?? [])
                .sorted { ($0.order_index ?? 0) < ($1.order_index ?? 0) }
                .map { row in
                    row.toSection(children: buildChildren(parentId: row.id))
                }
        }

        result[pieceId] = buildChildren(parentId: nil)
    }
    return result
}

// MARK: - Update DTOs

struct ArtistUpdate: Codable, Sendable {
    var name: String?
    var type: String?
    var genre: String?
    var country: String?
    var members: [String]?
}

struct WorkUpdate: Codable, Sendable {
    var title: String?
    var work_type: String?
    var genre: String?
    var country: String?
    var release_date: String?
    var opus: String?
    var premiere_location: String?
    var film_title: String?
    var director: String?
    var awards: [String]?
    var label: String?
    var producer: String?
    var recording_studio: String?
    var notes: String?
}

struct PieceUpdate: Codable, Sendable {
    var title: String?
    var piece_number: Int?
    var composer: String?
    var key_signature: String?
    var time_signature: String?
    var tempo_bpm: Double?
    var duration_ms: Int?
    var feel: String?
    var genre: String?
    var form: String?
    var listened: Bool?
    var score_read: Bool?
    var transcribed: Bool?
    var analyzed: Bool?
    var played: Bool?
}

struct SectionInsert: Codable, Sendable {
    var piece_id: UUID
    var parent_section_id: UUID?
    var label: String?
    var section_type: String
    var start_time_ms: Int?
    var end_time_ms: Int?
    var order_index: Int?
    var notes: String?
}

struct ArtistInsert: Codable, Sendable {
    var name: String
    var type: String?
    var genre: String?
    var country: String?
}

struct WorkInsert: Codable, Sendable {
    var artist_id: UUID
    var title: String
    var work_type: String?
    var genre: String?
}

struct PieceInsert: Codable, Sendable {
    var work_id: UUID
    var title: String
    var piece_number: Int?
}

// MARK: - Update Functions

func updateArtist(id: UUID, update: ArtistUpdate) async throws {
    try await supabase
        .schema("music")
        .from("artist")
        .update(update)
        .eq("id", value: id)
        .execute()
}

func updateWork(id: UUID, update: WorkUpdate) async throws {
    try await supabase
        .schema("music")
        .from("work")
        .update(update)
        .eq("id", value: id)
        .execute()
}

func updatePiece(id: UUID, update: PieceUpdate) async throws {
    try await supabase
        .schema("music")
        .from("piece")
        .update(update)
        .eq("id", value: id)
        .execute()
}
func insertSection(_ section: SectionInsert) async throws {
    try await supabase
        .schema("music")
        .from("section")
        .insert(section)
        .execute()
}

func deleteSection(id: UUID) async throws {
    try await supabase
        .schema("music")
        .from("section")
        .delete()
        .eq("id", value: id)
        .execute()
}

func insertArtist(_ artist: ArtistInsert) async throws {
    try await supabase
        .schema("music")
        .from("artist")
        .insert(artist)
        .execute()
}

func insertWork(_ work: WorkInsert) async throws {
    try await supabase
        .schema("music")
        .from("work")
        .insert(work)
        .execute()
}

func insertPiece(_ piece: PieceInsert) async throws {
    try await supabase
        .schema("music")
        .from("piece")
        .insert(piece)
        .execute()
}

