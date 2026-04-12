import Foundation

@Observable
class DataProvider {
    var artists: [Artist] = []
    var works: [Work] = []
    var isLoading = false
    var error: String?

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
            form: piece.form
        )
        try await updatePiece(id: piece.id, update: update)
        await loadAll()
    }
}
