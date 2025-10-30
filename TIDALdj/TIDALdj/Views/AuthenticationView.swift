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
            if let message = viewModel.authenticationError {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            Button(action: viewModel.signIn) {
                if viewModel.isAuthenticating {
                    ProgressView()
                        .tint(.white)
                        .padding(.horizontal, 32)
                } else {
                    Label("Sign in with TIDAL", systemImage: "person.crop.circle")
                        .padding(.horizontal, 32)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isAuthenticating)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AuthenticationView(viewModel: AppViewModel.preview())
}
