import Foundation
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif
internal import Combine

@MainActor
final class AppViewModel: NSObject, ObservableObject {
    
    @Published var isAuthenticated = false
    @Published var isPresentingLibrary = false
    @Published var selectedDeck: DeckID?
    @Published var crossfaderPosition: Float = 0.5 {
        didSet {
            let position = crossfaderPosition
            Task { await audioEngine.setCrossfader(position: position) }
        }
    }
    @Published var userProfile: UserProfile?
    @Published var isAuthenticating = false
    @Published var authenticationError: String?

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
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authenticationError = nil

        Task { @MainActor in
            do {
                let profile = try await apiService.authenticate(presentationContextProvider: self)
                userProfile = profile
                isAuthenticated = true
                await libraryViewModel.refreshPlaylists()
            } catch {
                if case TIDALApiService.ServiceError.authenticationCancelled = error {
                    authenticationError = nil
                } else {
                    authenticationError = error.localizedDescription
                }
                isAuthenticated = false
            }
            isAuthenticating = false
        }
    }

    func signOut() {
        Task { await apiService.signOut() }
        isAuthenticated = false
        isPresentingLibrary = false
        selectedDeck = nil
        userProfile = nil
        authenticationError = nil
        isAuthenticating = false
        libraryViewModel.reset()
        deckAViewModel.reset()
        deckBViewModel.reset()
    }

    func presentLibrary(for deck: DeckID) {
        selectedDeck = deck
        libraryViewModel.searchQuery = ""
        libraryViewModel.tracks = []
        Task { await libraryViewModel.performSearch() }
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
        AppViewModel(apiService: TIDALApiService(configuration: .preview), audioEngine: AudioEngine())
    }
}

extension AppViewModel: ASWebAuthenticationPresentationContextProviding {
    @MainActor
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
#if canImport(UIKit)
        if #available(iOS 26.0, *) {
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {
                return ASPresentationAnchor(windowScene: scene)
            }
        }
        // Fallback for iOS versions prior to 26.0 (or if no scene was found)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first ?? ASPresentationAnchor()
#else
        return ASPresentationAnchor()
#endif
    }
}
