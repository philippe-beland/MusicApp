import Foundation
import SwiftUI

enum PieceStatusFilter: String, CaseIterable {
    case listened, scoreRead, transcribed, analyzed, played

    var label: String {
        switch self {
        case .listened: "Listened"
        case .scoreRead: "Score"
        case .transcribed: "Transcribed"
        case .analyzed: "Analyzed"
        case .played: "Played"
        }
    }

    var icon: String {
        switch self {
        case .listened: "ear"
        case .scoreRead: "book"
        case .transcribed: "list.clipboard"
        case .analyzed: "chart.bar.doc.horizontal"
        case .played: "guitars"
        }
    }

    var color: Color {
        switch self {
        case .listened: .blue
        case .scoreRead: .orange
        case .transcribed: .green
        case .analyzed: .purple
        case .played: .red
        }
    }

    func isCompleted(in piece: Piece) -> Bool {
        switch self {
        case .listened: piece.listened
        case .scoreRead: piece.scoreRead
        case .transcribed: piece.transcribed
        case .analyzed: piece.analyzed
        case .played: piece.played
        }
    }
}

@Observable
class DataProvider {
    var artists: [Artist] = []
    var works: [Work] = []
    var isLoading = false
    var error: String?

    // Active filters — when a filter is on, pieces that already have that status are hidden
    var activeFilters: Set<PieceStatusFilter> = []

    var isFiltering: Bool { !activeFilters.isEmpty }

    func piecePassesFilters(_ piece: Piece) -> Bool {
        for filter in activeFilters {
            if filter.isCompleted(in: piece) { return false }
        }
        return true
    }

    var filteredWorks: [Work] {
        guard isFiltering else { return works }
        return works.compactMap { work in
            let kept = work.pieces.filter { piecePassesFilters($0) }
            guard !kept.isEmpty else { return nil }
            var filtered = work
            filtered.pieces = kept
            return filtered
        }
    }

    func filteredArtists(from artistList: [Artist], works workList: [Work]) -> [Artist] {
        guard isFiltering else { return artistList }
        let worksWithPieces = (workList.isEmpty ? filteredWorks : workList.compactMap { work in
            let kept = work.pieces.filter { piecePassesFilters($0) }
            guard !kept.isEmpty else { return nil }
            var filtered = work
            filtered.pieces = kept
            return filtered
        })
        let artistIdsWithWork = Set(worksWithPieces.map(\.artist.id))
        return artistList.filter { artistIdsWithWork.contains($0.id) }
    }

    func loadAll() async {
        isLoading = true
        error = nil

        do {
            artists = try await fetchArtists()
            works = try await fetchWorksWithPieces()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func saveArtist(_ artist: Artist) async throws {
        let update = ArtistUpdate(
            name: artist.name,
            type: artist.type.rawValue,
            genre: artist.genres.rawValue,
            country: artist.country,
            members: artist.members
        )
        try await updateArtist(id: artist.id, update: update)
        await loadAll()
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    func saveWork(_ work: Work) async throws {
        let update = WorkUpdate(
            title: work.title,
            work_type: work.workType.rawValue,
            genre: work.genre.rawValue,
            country: work.country,
            release_date: work.releaseDate.map { Self.dateFormatter.string(from: $0) },
            opus: work.opus,
            premiere_location: work.premiereLocation,
            film_title: work.filmTitle,
            director: work.director,
            awards: work.awards,
            label: work.label,
            producer: work.producer,
            recording_studio: work.recordingStudio,
            notes: work.notes
        )
        try await updateWork(id: work.id, update: update)
        await loadAll()
    }

    func savePiece(_ piece: Piece) async throws {
        let update = PieceUpdate(
            title: piece.title,
            piece_number: piece.pieceNumber,
            composer: piece.composer,
            key_signature: piece.keySignature,
            time_signature: piece.timeSignature,
            tempo_bpm: piece.tempoBPM,
            duration_ms: piece.durationMS,
            feel: piece.feel,
            genre: piece.genre?.rawValue,
            form: piece.form,
            listened: piece.listened,
            score_read: piece.scoreRead,
            transcribed: piece.transcribed,
            analyzed: piece.analyzed,
            played: piece.played
        )
        try await updatePiece(id: piece.id, update: update)
        await loadAll()
    }

    func createArtist(name: String, type: ArtistType, genre: Genre, country: String?) async throws {
        let insert = ArtistInsert(
            name: name,
            type: type.rawValue,
            genre: genre.rawValue,
            country: country
        )
        try await insertArtist(insert)
        await loadAll()
    }

    func createWork(artistId: UUID, title: String, workType: WorkType, genre: Genre) async throws {
        let insert = WorkInsert(
            artist_id: artistId,
            title: title,
            work_type: workType.rawValue,
            genre: genre.rawValue
        )
        try await insertWork(insert)
        await loadAll()
    }

    func createPiece(workId: UUID, title: String, pieceNumber: Int?) async throws {
        let insert = PieceInsert(
            work_id: workId,
            title: title,
            piece_number: pieceNumber
        )
        try await insertPiece(insert)
        await loadAll()
    }
}
