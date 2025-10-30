import SwiftUI

@main
struct TIDALdjApp: App {
    @StateObject private var appViewModel = AppViewModel(
        apiService: TIDALApiService(),
        audioEngine: AudioEngine()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: appViewModel)
        }
    }
}
