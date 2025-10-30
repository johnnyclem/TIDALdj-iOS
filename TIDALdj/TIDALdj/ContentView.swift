import SwiftUI
internal import Combine

@MainActor
struct ContentView: View {
    @StateObject private var viewModel: AppViewModel

    init(viewModel: @autoclosure @escaping () -> AppViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    init() {
        _viewModel = StateObject(wrappedValue: AppViewModel.preview())
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
