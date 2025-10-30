import Foundation
internal import Combine

@MainActor
final class AppViewModel: ObservableObject {
    
    @Published var isAuthenticated = false
    @Published var isPresentingLibrary = false
    @Published var selectedDeck: DeckID?
    @Published var crossfaderPosition: Float = 0.5 {
        didSet {
            let position = crossfaderPosition
            Task { await audioEngine.setCrossfader(position: position) }
        }
    }

    let apiService: TIDALApiService
    let audioEngine: AudioEngine
    let libraryViewModel: LibraryViewModel
    let deckAViewModel: DeckViewModel
    let deckBViewModel: DeckViewModel

    init(apiService: TIDALApiService, audioEngine: AudioEngine) {
        self.apiService = apiService
        self.audioEngine = audioEngine
        self.libraryViewModel = LibraryViewModel(apiService: apiService)
        self.deckAViewModel = DeckViewModel(deckID: .deckA, audioEngine: audioEngine)
        self.deckBViewModel = DeckViewModel(deckID: .deckB, audioEngine: audioEngine)
    }

    func signIn() {
        Task {
            await apiService.updateTokens(access: "mock_access_token", refresh: "mock_refresh_token")
            isAuthenticated = true
            await libraryViewModel.refreshPlaylists()
        }
    }

    func signOut() {
        Task { await apiService.clearTokens() }
        isAuthenticated = false
        isPresentingLibrary = false
        selectedDeck = nil
        deckAViewModel.reset()
        deckBViewModel.reset()
    }

    func presentLibrary(for deck: DeckID) {
        selectedDeck = deck
        libraryViewModel.searchQuery = ""
        libraryViewModel.tracks = []
        isPresentingLibrary = true
    }

    func handleTrackSelection(_ track: Track, deck: DeckID) {
        switch deck {
        case .deckA:
            deckAViewModel.loadTrack(track)
        case .deckB:
            deckBViewModel.loadTrack(track)
        }
        isPresentingLibrary = false
        selectedDeck = nil
    }

    func sync(deck: DeckID) {
        switch deck {
        case .deckA:
            deckAViewModel.sync(to: deckBViewModel.currentBPM)
        case .deckB:
            deckBViewModel.sync(to: deckAViewModel.currentBPM)
        }
    }
}

extension AppViewModel {
    static func preview() -> AppViewModel {
        AppViewModel(apiService: TIDALApiService(), audioEngine: AudioEngine())
    }
}
