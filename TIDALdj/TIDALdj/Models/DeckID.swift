import Foundation

enum DeckID: Hashable {
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
