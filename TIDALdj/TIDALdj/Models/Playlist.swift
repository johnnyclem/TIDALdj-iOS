import Foundation

struct Playlist: Identifiable, Hashable {
    let id: String
    let name: String
    let trackCount: Int

    init(id: String, name: String, trackCount: Int) {
        self.id = id
        self.name = name
        self.trackCount = trackCount
    }
}
