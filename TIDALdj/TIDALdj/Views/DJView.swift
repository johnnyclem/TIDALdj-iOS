import SwiftUI

struct DJView: View {
    @ObservedObject var appViewModel: AppViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    DeckView(
                        viewModel: appViewModel.deckAViewModel,
                        onLoadTrack: { appViewModel.presentLibrary(for: .deckA) },
                        onSync: { appViewModel.sync(deck: .deckA) }
                    )
                    DeckView(
                        viewModel: appViewModel.deckBViewModel,
                        onLoadTrack: { appViewModel.presentLibrary(for: .deckB) },
                        onSync: { appViewModel.sync(deck: .deckB) }
                    )
                }
                .padding(.horizontal)
                CrossfaderView(position: $appViewModel.crossfaderPosition)
                    .padding(.horizontal)
            }
            .navigationTitle("TIDAL DJ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Library") {
                        appViewModel.presentLibrary(for: appViewModel.selectedDeck ?? .deckA)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out", action: appViewModel.signOut)
                }
            }
        }
    }
}

#Preview {
    DJView(appViewModel: AppViewModel.preview())
}
