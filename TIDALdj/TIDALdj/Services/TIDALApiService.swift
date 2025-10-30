import Foundation

actor TIDALApiService {
    private var accessToken: String?
    private var refreshToken: String?
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: - Authentication

    func updateTokens(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
    }

    // MARK: - Playlist APIs

    func getUserPlaylists() async throws -> [Playlist] {
        // Placeholder implementation until SDK integration is completed.
        return []
    }

    func getPlaylistTracks(id: String) async throws -> [Track] {
        // Placeholder implementation until SDK integration is completed.
        return []
    }

    func search(query: String) async throws -> [Track] {
        guard !query.isEmpty else { return [] }
        // Placeholder implementation until SDK integration is completed.
        return []
    }

    func createPlaylist(name: String) async throws -> Playlist {
        // Placeholder implementation until SDK integration is completed.
        return await Playlist(id: UUID().uuidString, name: name, trackCount: 0)
    }

    func addTrackToPlaylist(trackId: String, playlistId: String) async throws {
        // Placeholder implementation until SDK integration is completed.
    }

    func removeTrackFromPlaylist(trackId: String, playlistId: String) async throws {
        // Placeholder implementation until SDK integration is completed.
    }
}
