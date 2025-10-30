import SwiftUI

struct DeckView: View {
    @ObservedObject var viewModel: DeckViewModel
    var onLoadTrack: () -> Void
    var onSync: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(alignment: .center) {
                        if let albumURL = viewModel.albumArtURL {
                            AsyncImage(url: albumURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Image(systemName: "circle.dashed")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 180, height: 180)
                    .shadow(radius: 8)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                viewModel.platterWasDragged(translation: value.translation)
                            }
                    )
                if viewModel.isPlaying {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 4)
                        .frame(width: 200, height: 200)
                        .animation(.easeInOut, value: viewModel.isPlaying)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .font(.headline)
                if !viewModel.subtitle.isEmpty {
                    Text(viewModel.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let bpm = viewModel.currentBPM {
                    Text("BPM: \(bpm, specifier: "%.1f")")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(action: viewModel.playPauseTapped) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                .buttonStyle(.bordered)

                Button(action: onLoadTrack) {
                    Label("Load", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.bordered)

                Button(action: onSync) {
                    Label("Sync", systemImage: "metronome")
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading) {
                Text("Tempo")
                    .font(.subheadline)
                Slider(
                    value: Binding(
                        get: { Double(viewModel.tempo) },
                        set: { viewModel.tempoSliderChanged(to: Float($0)) }
                    ),
                    in: 0.92...1.08
                )
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
    }
}

#Preview {
    DeckView(
        viewModel: AppViewModel.preview().deckAViewModel,
        onLoadTrack: {},
        onSync: {}
    )
    .frame(width: 260)
}
