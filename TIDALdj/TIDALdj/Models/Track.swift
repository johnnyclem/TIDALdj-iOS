import Foundation

struct Track: Identifiable, Hashable {
    let id: String
    let title: String
    let artistName: String
    let albumTitle: String
    let albumArtURL: URL?
    let originalBPM: Double?

    init(
        id: String,
        title: String,
        artistName: String,
        albumTitle: String,
        albumArtURL: URL? = nil,
        originalBPM: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.albumArtURL = albumArtURL
        self.originalBPM = originalBPM
    }
}
