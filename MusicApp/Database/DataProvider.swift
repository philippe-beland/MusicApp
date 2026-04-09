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
}
