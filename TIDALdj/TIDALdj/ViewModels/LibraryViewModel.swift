import Foundation
internal import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var tracks: [Track] = []
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService: TIDALApiService
    private var userPlaylists: [Playlist] = []

    init(apiService: TIDALApiService) {
        self.apiService = apiService
    }

    var playlistSectionTitle: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Playlists" : "Playlist Results"
    }

    var tracksSectionTitle: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Tracks" : "Track Results"
    }

    var isShowingSearchResults: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func refreshPlaylists() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let playlists = try await apiService.getUserPlaylists()
            userPlaylists = playlists
            self.playlists = playlists
            tracks = []
            searchQuery = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTracks(for playlist: Playlist) async {
        isLoading = true
        defer { isLoading = false }
        do {
            tracks = try await apiService.getPlaylistTracks(id: playlist.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func performSearch() async {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            playlists = userPlaylists
            tracks = []
            errorMessage = nil
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let results = try await apiService.search(query: trimmedQuery)
            playlists = results.playlists
            tracks = results.tracks
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        playlists = []
        tracks = []
        searchQuery = ""
        isLoading = false
        errorMessage = nil
        userPlaylists = []
    }
}
