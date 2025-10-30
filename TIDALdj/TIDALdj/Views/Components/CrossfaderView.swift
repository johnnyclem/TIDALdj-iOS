import SwiftUI

struct CrossfaderView: View {
    @Binding var position: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Crossfader")
                .font(.headline)
            Slider(value: Binding(
                get: { Double(position) },
                set: { position = Float($0) }
            ), in: 0...1)
        }
    }
}

#Preview {
    CrossfaderView(position: .constant(0.5))
        .padding()
}
