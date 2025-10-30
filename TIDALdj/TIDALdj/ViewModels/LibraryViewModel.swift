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

    init(apiService: TIDALApiService) {
        self.apiService = apiService
    }

    func refreshPlaylists() async {
        isLoading = true
        defer { isLoading = false }
        do {
            playlists = try await apiService.getUserPlaylists()
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
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            tracks = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            tracks = try await apiService.search(query: searchQuery)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
