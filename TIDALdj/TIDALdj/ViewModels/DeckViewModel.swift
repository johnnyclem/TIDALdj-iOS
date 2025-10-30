import CoreGraphics
import Foundation
internal import Combine

@MainActor
final class DeckViewModel: ObservableObject {
    @Published private(set) var track: Track?
    @Published var isPlaying = false
    @Published var tempo: Float = 1.0
    @Published var currentBPM: Double?

    let deckID: DeckID

    private let audioEngine: AudioEngine
    private let tempoRange: ClosedRange<Float> = 0.92...1.08

    init(deckID: DeckID, audioEngine: AudioEngine) {
        self.deckID = deckID
        self.audioEngine = audioEngine
    }

    var title: String {
        track?.title ?? "Load a track"
    }

    var subtitle: String {
        guard let track else { return "" }
        return "\(track.artistName) • \(track.albumTitle)"
    }

    var albumArtURL: URL? {
        track?.albumArtURL
    }

    func loadTrack(_ track: Track) {
        self.track = track
        currentBPM = track.originalBPM
        tempo = 1.0
        Task {
            try? await audioEngine.loadTrack(deck: deckID, track: track)
        }
    }

    func reset() {
        track = nil
        currentBPM = nil
        tempo = 1.0
        isPlaying = false
        Task { await audioEngine.pause(deck: deckID) }
    }

    func playPauseTapped() {
        isPlaying.toggle()
        let playing = isPlaying
        Task {
            if playing {
                await audioEngine.play(deck: deckID)
            } else {
                await audioEngine.pause(deck: deckID)
            }
        }
    }

    func tempoSliderChanged(to newValue: Float) {
        let clampedValue = max(tempoRange.lowerBound, min(newValue, tempoRange.upperBound))
        tempo = clampedValue
        if let originalBPM = track?.originalBPM {
            currentBPM = Double(clampedValue) * originalBPM
        } else {
            currentBPM = nil
        }
        Task { await audioEngine.setTempo(deck: deckID, rate: clampedValue) }
    }

    func sync(to masterBPM: Double?) {
        guard let originalBPM = track?.originalBPM, let masterBPM else { return }
        let desiredTempo = Float(masterBPM / originalBPM)
        tempoSliderChanged(to: desiredTempo)
    }

    func platterWasDragged(translation: CGSize) {
        // Interpret horizontal drag as a scratch delta for now.
        let sensitivity: TimeInterval = 0.02
        let offset = TimeInterval(translation.width) * sensitivity
        Task { await audioEngine.seek(deck: deckID, position: offset) }
    }
}
