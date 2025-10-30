import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("TIDAL DJ")
                .font(.largeTitle.bold())
            Text("Sign in with your TIDAL account to continue.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(action: viewModel.signIn) {
                Label("Sign in with TIDAL", systemImage: "person.crop.circle")
                    .padding(.horizontal, 32)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AuthenticationView(viewModel: AppViewModel.preview())
}
