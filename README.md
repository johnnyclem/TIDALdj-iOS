# TIDALdj-iOS

Proof-of-concept for an iOS DJ application that leans entirely on the TIDAL ecosystem. The project is structured around SwiftUI, MVVM, and actor-isolated services so we can validate the critical flows outlined in the PRD.

## Architecture Overview

- **Models** – Lightweight value types for playlists, tracks, and deck identifiers that mirror the data returned from the TIDAL SDK/API.
- **Services (Actors)** – `TIDALApiService` and `AudioEngine` encapsulate async work and stateful resources. The current implementation provides safe placeholders until the official SDK is wired in.
- **ViewModels** – `AppViewModel`, `LibraryViewModel`, and `DeckViewModel` own presentation state for authentication, library management, and each playback deck respectively.
- **Views** – SwiftUI views (`AuthenticationView`, `DJView`, `DeckView`, `LibraryView`, and supporting components) render the UI and delegate actions back to the view models.

## Getting Started

1. Open `TIDALdj.xcodeproj` with Xcode 16+.
2. Select the **TIDALdj** scheme and run it on an iOS 17 simulator or device.
3. Use the mock sign-in button to explore the placeholder UI while the TIDAL SDK integration is under development.

## Next Steps

- Replace the mock authentication with the official TIDAL OAuth flow.
- Implement real playlist and search requests via the TIDAL SDK/API.
- Flesh out the `AudioEngine` actor once Player integration details are confirmed by the spike.
