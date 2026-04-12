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
}

struct FileRow: Codable, Sendable {
    let id: UUID
    let piece_id: UUID?
    let source_type: String
    let file_path: String?
    let storage_url: String?
    let is_primary: Bool?
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

extension PieceRow {
    func toPiece(files: [File] = []) -> Piece {
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
        .from("artist")
        .select()
        .execute()
        .value
    return rows.map { $0.toArtist() }
}

func fetchWorksWithPieces() async throws -> [Work] {
    // Fetch works with embedded artist
    let workRows: [WorkRow] = try await supabase
        .from("work")
        .select("*, artist(*)")
        .execute()
        .value

    // Fetch all pieces
    let pieceRows: [PieceRow] = try await supabase
        .from("piece")
        .select()
        .execute()
        .value

    // Fetch all files
    let fileRows: [FileRow] = try await supabase
        .from("file")
        .select()
        .execute()
        .value

    // Group files by piece_id
    let filesByPiece = Dictionary(grouping: fileRows, by: { $0.piece_id })

    // Group pieces by work_id
    let piecesByWork = Dictionary(grouping: pieceRows, by: { $0.work_id })

    // Assemble works with their pieces and files
    return workRows.map { row in
        let pieces = (piecesByWork[row.id] ?? [])
            .sorted { ($0.piece_number ?? 0) < ($1.piece_number ?? 0) }
            .map { pieceRow in
                let files = (filesByPiece[pieceRow.id] ?? []).map { $0.toFile() }
                return pieceRow.toPiece(files: files)
            }
        return row.toWork(pieces: pieces)
    }
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
}

// MARK: - Update Functions

func updateArtist(id: UUID, update: ArtistUpdate) async throws {
    try await supabase
        .from("artist")
        .update(update)
        .eq("id", value: id)
        .execute()
}

func updateWork(id: UUID, update: WorkUpdate) async throws {
    try await supabase
        .from("work")
        .update(update)
        .eq("id", value: id)
        .execute()
}

func updatePiece(id: UUID, update: PieceUpdate) async throws {
    try await supabase
        .from("piece")
        .update(update)
        .eq("id", value: id)
        .execute()
}
