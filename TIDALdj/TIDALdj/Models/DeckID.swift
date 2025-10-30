import Foundation

enum DeckID {
    case deckA
    case deckB

    var displayName: String {
        switch self {
        case .deckA:
            return "Deck A"
        case .deckB:
            return "Deck B"
        }
    }
}

nonisolated extension DeckID: Hashable {}
