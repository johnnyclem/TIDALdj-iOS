import SwiftUI

struct LibraryView: View {
    @ObservedObject var viewModel: LibraryViewModel
    var preferredDeck: DeckID?
    var onTrackSelected: (Track, DeckID) -> Void

    var body: some View {
        NavigationStack {
            List {
                if let preferredDeck {
                    Section {
                        Text("Loading tracks for \(preferredDeck.displayName)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if !viewModel.playlists.isEmpty {
                    Section(viewModel.playlistSectionTitle) {
                        ForEach(viewModel.playlists) { playlist in
                            Button {
                                Task { await viewModel.loadTracks(for: playlist) }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(playlist.name)
                                        Text("\(playlist.trackCount) tracks")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }

                if !viewModel.tracks.isEmpty {
                    Section(viewModel.tracksSectionTitle) {
                        ForEach(viewModel.tracks) { track in
                            trackMenu(for: track)
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                } else if let message = viewModel.errorMessage {
                    ContentUnavailableView("Unable to load library", systemImage: "exclamationmark.triangle", description: Text(message))
                } else if viewModel.isShowingSearchResults && viewModel.playlists.isEmpty && viewModel.tracks.isEmpty {
                    ContentUnavailableView("No results", systemImage: "magnifyingglass", description: Text("Try a different search query."))
                } else if viewModel.playlists.isEmpty && viewModel.tracks.isEmpty {
                    ContentUnavailableView("No content", systemImage: "music.note", description: Text("Use search to find tracks."))
                }
            }
            .searchable(text: $viewModel.searchQuery)
            .onSubmit(of: .search) {
                Task { await viewModel.performSearch() }
            }
            .task {
                await viewModel.refreshPlaylists()
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") {
                        Task { await viewModel.performSearch() }
                    }
                    .disabled(viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func trackMenu(for track: Track) -> some View {
        Menu {
            if let preferredDeck {
                Button("Load on \(preferredDeck.displayName)") {
                    onTrackSelected(track, preferredDeck)
                }
                Divider()
            }
            Button("Load on Deck A") { onTrackSelected(track, .deckA) }
            Button("Load on Deck B") { onTrackSelected(track, .deckB) }
        } label: {
            VStack(alignment: .leading) {
                Text(track.title)
                Text(track.artistName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    LibraryView(viewModel: AppViewModel.preview().libraryViewModel, preferredDeck: .deckA, onTrackSelected: { _, _ in })
}
