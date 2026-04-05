import Foundation

@Observable
class DataProvider {
    var useSampleData = true
    var artists: [Artist] = []
    var works: [Work] = []
    var isLoading = false
    var error: String?

    func loadAll() async {
        isLoading = true
        error = nil

        if useSampleData {
            artists = SampleData.allArtists
            works = SampleData.allWorks
        } else {
            do {
                artists = try await fetchArtists()
                works = try await fetchWorksWithPieces()
            } catch {
                self.error = error.localizedDescription
                // Fall back to sample data on error
                artists = SampleData.allArtists
                works = SampleData.allWorks
            }
        }

        isLoading = false
    }

    /// Toggle between sample and real data, then reload
    func toggleDataSource() async {
        useSampleData.toggle()
        await loadAll()
    }
}
