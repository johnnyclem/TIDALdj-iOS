import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: AppViewModel

    init(viewModel: @autoclosure @escaping () -> AppViewModel = AppViewModel.preview()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                DJView(appViewModel: viewModel)
                    .sheet(isPresented: $viewModel.isPresentingLibrary) {
                        LibraryView(
                            viewModel: viewModel.libraryViewModel,
                            preferredDeck: viewModel.selectedDeck
                        ) { track, deck in
                            viewModel.handleTrackSelection(track, deck: deck)
                        }
                    }
            } else {
                AuthenticationView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut, value: viewModel.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
