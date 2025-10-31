import Foundation
import AuthenticationServices
import CryptoKit

actor TIDALApiService {
    struct Configuration {
        let clientID: String
        let clientSecret: String
        let redirectURI: URL
        let scopes: [String]
        let authorizationURL: URL
        let tokenURL: URL
        let revokeURL: URL
        let apiBaseURL: URL

        static let defaultScopes: [String] = [
            "user.read",
            "collection.read",
            "playlists.read",
            "recommendations.read"
        ]

        static func loadFromBundle() -> Configuration {
            guard let clientID = Bundle.main.object(forInfoDictionaryKey: InfoKey.clientID) as? String,
                  !clientID.isEmpty else {
                preconditionFailure("Missing TIDAL client identifier (Info.plist key \(InfoKey.clientID)).")
            }


            // For PKCE on a native app, a client secret is not required; make it optional.
            let clientSecret = (Bundle.main.object(forInfoDictionaryKey: InfoKey.clientSecret) as? String) ?? ""


            let redirectString = (Bundle.main.object(forInfoDictionaryKey: InfoKey.redirectURI) as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let redirectURI = URL(string: redirectString ?? "tidaldj://preview")
            precondition(redirectURI != nil, "Invalid redirect URI. Update Info.plist key \(InfoKey.redirectURI).")

            return Configuration(
                clientID: clientID,
                clientSecret: clientSecret,
                redirectURI: redirectURI!,
                scopes: defaultScopes,
                authorizationURL: URL(string: "https://login.tidal.com/authorize")!,
                tokenURL: URL(string: "https://auth.tidal.com/v1/oauth2/token")!,
                revokeURL: URL(string: "https://auth.tidal.com/v1/oauth2/revoke")!,
                apiBaseURL: URL(string: "https://openapi.tidal.com/v1")!
            )
        }

        fileprivate enum InfoKey {
            static let clientID = "kTidalClientID"
            static let clientSecret = "kTidalClientSecret"
            static let redirectURI = "kTidalRedirectURI"
        }

        static let preview = Configuration(
            clientID: "preview",
            clientSecret: "preview",
            redirectURI: URL(string: "tidaldj://preview")!,
            scopes: defaultScopes,
            authorizationURL: URL(string: "https://login.tidal.com/authorize")!,
            tokenURL: URL(string: "https://auth.tidal.com/v1/oauth2/token")!,
            revokeURL: URL(string: "https://auth.tidal.com/v1/oauth2/revoke")!,
            apiBaseURL: URL(string: "https://openapi.tidal.com/v1")!
        )
    }

    enum ServiceError: LocalizedError {
        case authenticationCancelled
        case invalidCallbackURL
        case missingAuthorizationCode
        case stateMismatch
        case invalidHTTPStatus(Int)
        case invalidResponse
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .authenticationCancelled:
                return "Authentication was cancelled."
            case .invalidCallbackURL:
                return "Received invalid authentication callback."
            case .missingAuthorizationCode:
                return "Authentication response was missing an authorization code."
            case .stateMismatch:
                return "The authentication response did not match the expected state."
            case .invalidHTTPStatus(let status):
                return "TIDAL API returned an unexpected status code: \(status)."
            case .invalidResponse:
                return "The TIDAL API returned an invalid response."
            case .notAuthenticated:
                return "You must be signed in to perform this action."
            }
        }
    }

    private struct OAuthTokens {
        let accessToken: String
        let refreshToken: String
        let expiresAt: Date
        let scope: String?
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let tokenType: String
        let expiresIn: Int
        let refreshToken: String?
        let scope: String?
    }

    private struct UserProfileResponse: Decodable {
        let userId: String
        let email: String?
        let firstName: String?
        let lastName: String?
        let fullName: String?
        let nickname: String?
        let countryCode: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let stringID = try? container.decode(String.self, forKey: .userId) {
                userId = stringID
            } else if let intID = try? container.decode(Int.self, forKey: .userId) {
                userId = String(intID)
            } else {
                throw DecodingError.keyNotFound(CodingKeys.userId, .init(codingPath: decoder.codingPath, debugDescription: "Missing user identifier"))
            }
            email = try container.decodeIfPresent(String.self, forKey: .email)
            firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
            lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
            fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
            nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
            countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        }

        enum CodingKeys: String, CodingKey {
            case userId
            case email
            case firstName
            case lastName
            case fullName
            case nickname
            case countryCode
        }
    }

    private struct PagedResponse<Item: Decodable>: Decodable {
        let items: [Item]
    }

    internal struct TrackResponse: Decodable {
        struct Artist: Decodable {
            let name: String
        }

        struct Album: Decodable {
            let title: String
            let cover: String?
        }

        let id: String
        let title: String
        let artists: [Artist]?
        let album: Album?
        let bpm: Double?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let stringID = try? container.decode(String.self, forKey: .id) {
                id = stringID
            } else if let intID = try? container.decode(Int.self, forKey: .id) {
                id = String(intID)
            } else {
                throw DecodingError.keyNotFound(CodingKeys.id, .init(codingPath: decoder.codingPath, debugDescription: "Missing track identifier"))
            }
            title = try container.decode(String.self, forKey: .title)
            artists = try container.decodeIfPresent([Artist].self, forKey: .artists)
            album = try container.decodeIfPresent(Album.self, forKey: .album)
            bpm = try container.decodeIfPresent(Double.self, forKey: .bpm)
        }

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case artists
            case album
            case bpm
        }
    }

    struct PlaylistResponse: Decodable {
        let uuid: String
        let title: String
        let numberOfTracks: Int

        enum CodingKeys: String, CodingKey {
            case uuid
            case title
            case numberOfTracks
        }
    }

    private struct SearchResponse: Decodable {
        let tracks: PagedResponse<TrackResponse>?
        let playlists: PagedResponse<PlaylistResponse>?
    }

    struct PKCE {
        let verifier: String
        let challenge: String
        let state: String

        init(length: Int = 64) async {
            let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
            var generator = SystemRandomNumberGenerator()
            let verifierCharacters = (0..<length).compactMap { _ in charset.randomElement(using: &generator) }
            verifier = String(verifierCharacters)

            let verifierData = Data(verifier.utf8)
            let challengeData = Data(SHA256.hash(data: verifierData))
            challenge = await MainActor.run { challengeData.base64URLEncodedString() }
            state = UUID().uuidString
        }
    }

    private let configuration: Configuration
    private let urlSession: URLSession

    private var tokens: OAuthTokens?
    private var cachedProfile: UserProfile?
    private var currentAuthSession: ASWebAuthenticationSession?

    init(configuration: Configuration? = nil, urlSession: URLSession = .shared) {
        self.configuration = configuration ?? Configuration.loadFromBundle()
        self.urlSession = urlSession
    }

    // MARK: - Authentication

    func authenticate(presentationContextProvider: ASWebAuthenticationPresentationContextProviding) async throws -> UserProfile {
        let pkce = await PKCE()

        let authorizationURL = try makeAuthorizationURL(using: pkce)
        let callbackURL = try await startAuthenticationSession(
            url: authorizationURL,
            callbackScheme: configuration.redirectURI.scheme,
            presentationContextProvider: presentationContextProvider
        )

        let authorizationCode = try extractAuthorizationCode(from: callbackURL, expectedState: pkce.state)
        let tokens = try await exchangeCodeForTokens(code: authorizationCode, pkce: pkce)
        self.tokens = tokens

        let profile = try await fetchCurrentUserProfile()
        cachedProfile = profile
        return profile
    }

    func signOut() async {
        if let tokens {
            var request = URLRequest(url: configuration.revokeURL)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let bodyItems = [
                URLQueryItem(name: "token", value: tokens.refreshToken),
                URLQueryItem(name: "client_id", value: configuration.clientID),
                URLQueryItem(name: "client_secret", value: configuration.clientSecret)
            ]
            request.httpBody = await bodyItems.percentEncoded()
            _ = try? await urlSession.data(for: request)
        }

        tokens = nil
        cachedProfile = nil
        clearAuthSession(cancel: true)
    }

    // MARK: - Library

    func getUserPlaylists() async throws -> [Playlist] {
        let profile = try await requireProfile()
        let url = try makeAPIURL(
            path: "/users/me/playlists",
            queryItems: [
                URLQueryItem(name: "limit", value: "50"),
                URLQueryItem(name: "offset", value: "0"),
                URLQueryItem(name: "countryCode", value: countryCode(for: profile))
            ]
        )

        let request = try await authorizedRequest(url: url)
        let response: PagedResponse<PlaylistResponse> = try await perform(request)
        return await MainActor.run {
            response.items.map { playlist in
                Playlist(
                    id: playlist.uuid,
                    name: playlist.title,
                    trackCount: playlist.numberOfTracks
                )
            }
        }
    }

    func getPlaylistTracks(id: String) async throws -> [Track] {
        let profile = try await requireProfile()
        let url = try makeAPIURL(
            path: "/playlists/\(id)/tracks",
            queryItems: [
                URLQueryItem(name: "limit", value: "50"),
                URLQueryItem(name: "offset", value: "0"),
                URLQueryItem(name: "countryCode", value: countryCode(for: profile))
            ]
        )

        let request = try await authorizedRequest(url: url)
        let response: PagedResponse<TrackResponse> = try await perform(request)
        return await MainActor.run { response.items.map { $0.toTrack() } }
    }

    func search(query: String) async throws -> SearchResults {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return SearchResults(tracks: [], playlists: [])
        }

        let profile = try await requireProfile()
        let url = try makeAPIURL(
            path: "/search",
            queryItems: [
                URLQueryItem(name: "query", value: trimmedQuery),
                URLQueryItem(name: "types", value: "TRACKS,PLAYLISTS"),
                URLQueryItem(name: "limit", value: "25"),
                URLQueryItem(name: "countryCode", value: countryCode(for: profile))
            ]
        )

        let request = try await authorizedRequest(url: url)
        let searchResponse: SearchResponse = try await perform(request)
        let tracks = await MainActor.run { (searchResponse.tracks?.items ?? []).map { $0.toTrack() } }
        let playlists =  await MainActor.run { (searchResponse.playlists?.items ?? []).map { $0.toPlaylist() } }
        return SearchResults(tracks: tracks, playlists: playlists)
    }

    // MARK: - Helpers

    private func requireProfile() async throws -> UserProfile {
        if let cachedProfile {
            return cachedProfile
        }
        guard tokens != nil else {
            throw ServiceError.notAuthenticated
        }
        let profile = try await fetchCurrentUserProfile()
        cachedProfile = profile
        return profile
    }

    private func makeAuthorizationURL(using pkce: PKCE) throws -> URL {
        // Do NOT add Authorization headers or tokens here. The authorize endpoint does not accept Bearer tokens;
        // tokens are obtained later from the token endpoint and used for API requests.
        var components = URLComponents(url: configuration.authorizationURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI.absoluteString),
            URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: pkce.state)
        ]

        guard let url = components?.url else {
            throw ServiceError.invalidResponse
        }
        return url
    }

    private func startAuthenticationSession(
        url: URL,
        callbackScheme: String?,
        presentationContextProvider: ASWebAuthenticationPresentationContextProviding
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
                    guard let self else { return }
                    Task {
                        await self.clearAuthSession()
                        if let error = error {
                            if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                                continuation.resume(throwing: ServiceError.authenticationCancelled)
                            } else {
                                continuation.resume(throwing: error)
                            }
                            return
                        }
                        guard let callbackURL else {
                            continuation.resume(throwing: ServiceError.invalidCallbackURL)
                            return
                        }
                        continuation.resume(returning: callbackURL)
                    }
                }
                session.presentationContextProvider = presentationContextProvider
                session.prefersEphemeralWebBrowserSession = false
                
                await storeAuthSession(session)

                if session.start() == false {
                    await clearAuthSession(cancel: true)
                    continuation.resume(throwing: ServiceError.invalidResponse)
                }
            }
        }
    }

    private func storeAuthSession(_ session: ASWebAuthenticationSession) {
        currentAuthSession = session
    }

    private func clearAuthSession(cancel: Bool = false) {
        if cancel {
            currentAuthSession?.cancel()
        }
        currentAuthSession = nil
    }

    private func extractAuthorizationCode(from callbackURL: URL, expectedState: String) throws -> String {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw ServiceError.invalidCallbackURL
        }

        if let errorItem = queryItems.first(where: { $0.name == "error" }), let errorValue = errorItem.value {
            throw NSError(domain: "com.tidaldj.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: errorValue])
        }

        guard let state = queryItems.first(where: { $0.name == "state" })?.value, state == expectedState else {
            throw ServiceError.stateMismatch
        }

        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            throw ServiceError.missingAuthorizationCode
        }
        return code
    }

    private func exchangeCodeForTokens(code: String, pkce: PKCE) async throws -> OAuthTokens {
        var request = URLRequest(url: configuration.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        if !configuration.clientSecret.isEmpty {
            let creds = "\(configuration.clientID):\(configuration.clientSecret)"
            if let data = creds.data(using: .utf8) {
                let basic = data.base64EncodedString()
                request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
            }
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var bodyItems: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI.absoluteString),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "code_verifier", value: pkce.verifier)
        ]

        request.httpBody = await bodyItems.percentEncoded()

        let response: TokenResponse = try await perform(request)
        guard let refreshToken = response.refreshToken ?? tokens?.refreshToken else {
            throw ServiceError.invalidResponse
        }
        let expiresIn = max(response.expiresIn - 60, 0)
        return OAuthTokens(
            accessToken: response.accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn)),
            scope: response.scope
        )
    }

    private func ensureValidAccessToken() async throws -> String {
        if let tokens, tokens.expiresAt > Date() {
            return tokens.accessToken
        }
        return try await refreshAccessToken()
    }

    private func refreshAccessToken() async throws -> String {
        guard let tokens else {
            throw ServiceError.notAuthenticated
        }

        var request = URLRequest(url: configuration.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if !configuration.clientSecret.isEmpty {
            let creds = "\(configuration.clientID):\(configuration.clientSecret)"
            if let data = creds.data(using: .utf8) {
                let basic = data.base64EncodedString()
                request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
            }
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var bodyItems: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: tokens.refreshToken),
            URLQueryItem(name: "client_id", value: configuration.clientID)
        ]
        request.httpBody = await bodyItems.percentEncoded()

        let response: TokenResponse = try await perform(request)
        let expiresIn = max(response.expiresIn - 60, 0)
        let newTokens = OAuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken ?? tokens.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn)),
            scope: response.scope
        )
        self.tokens = newTokens
        return newTokens.accessToken
    }

    private func authorizedRequest(url: URL) async throws -> URLRequest {
        let accessToken = try await ensureValidAccessToken()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.tidal.v1+json", forHTTPHeaderField: "Accept")
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)

        #if DEBUG
        if let url = request.url {
            let method = request.httpMethod ?? "GET"
            print("[TIDALApiService] Request: \(method) \(url.absoluteString)")
        }
        #endif

        func decode<U: Decodable>(_ data: Data) throws -> U {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(U.self, from: data)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        // Success path
        if (200...299).contains(httpResponse.statusCode) {
            #if DEBUG
            if let url = request.url {
                print("[TIDALApiService] Response: 2xx for \(url.absoluteString)")
            }
            #endif
            return try decode(data)
        }

        // If unauthorized and this was an authorized request, try a single refresh + retry
        if httpResponse.statusCode == 401,
           request.value(forHTTPHeaderField: "Authorization") != nil,
           tokens != nil {
            do {
                let newAccessToken = try await refreshAccessToken()
                var retryRequest = request
                retryRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await urlSession.data(for: retryRequest)
                guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                    throw ServiceError.invalidResponse
                }
                #if DEBUG
                if let url = retryRequest.url {
                    print("[TIDALApiService] Retry Response: \(retryHTTP.statusCode) for \(url.absoluteString)")
                }
                #endif
                guard (200...299).contains(retryHTTP.statusCode) else {
                    if retryHTTP.statusCode == 401 { tokens = nil }
                    throw ServiceError.invalidHTTPStatus(retryHTTP.statusCode)
                }
                return try decode(retryData)
            } catch {
                tokens = nil
                throw ServiceError.invalidHTTPStatus(401)
            }
        }

        // For other error statuses, try to surface token endpoint errors if present
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           contentType.contains("application/json"),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let description = (json["error_description"] as? String) ?? (json["message"] as? String) {
            throw NSError(domain: "com.tidaldj.api", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: description])
        }

        #if DEBUG
        if let url = request.url {
            let bodySnippet = String(data: data.prefix(256), encoding: .utf8) ?? "<non-utf8>"
            print("[TIDALApiService] Error Response: \(httpResponse.statusCode) for \(url.absoluteString) body: \(bodySnippet)")
        }
        #endif

        if httpResponse.statusCode == 401 { tokens = nil }
        throw ServiceError.invalidHTTPStatus(httpResponse.statusCode)
    }

    private func fetchCurrentUserProfile() async throws -> UserProfile {
        let url = try makeAPIURL(path: "/users/me")
        let request = try await authorizedRequest(url: url)
        let profileResponse: UserProfileResponse = try await perform(request)
        return UserProfile(
            id: profileResponse.userId,
            fullName: profileResponse.fullName ?? [profileResponse.firstName, profileResponse.lastName]
                .compactMap { $0 }
                .joined(separator: " "),
            firstName: profileResponse.firstName,
            lastName: profileResponse.lastName,
            nickname: profileResponse.nickname,
            email: profileResponse.email,
            countryCode: profileResponse.countryCode
        )
    }

    private func makeAPIURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var url = configuration.apiBaseURL
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        url.appendPathComponent(trimmedPath)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let filteredItems = queryItems.compactMap { item -> URLQueryItem? in
            guard let value = item.value else { return nil }
            return URLQueryItem(name: item.name, value: value)
        }
        if !filteredItems.isEmpty {
            components?.queryItems = filteredItems
        }
        guard let finalURL = components?.url else {
            throw ServiceError.invalidResponse
        }
        return finalURL
    }

    private func countryCode(for profile: UserProfile) -> String? {
        if let code = profile.countryCode, !code.isEmpty {
            return code
        }
        return Locale.current.region?.identifier
    }
}

private extension Array where Element == URLQueryItem {
    func percentEncoded() -> Data? {
        var components = URLComponents()
        components.queryItems = self
        return components.percentEncodedQuery?.data(using: .utf8)
    }
}

public extension Data {
    func base64URLEncodedString() -> String {
        let base64 = self.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension TIDALApiService.TrackResponse {
    func toTrack() -> Track {
        Track(
            id: id,
            title: title,
            artistName: artists?.first?.name ?? "Unknown Artist",
            albumTitle: album?.title ?? "",
            albumArtURL: album?.cover.flatMap { cover in
                let sanitized = cover
                    .replacingOccurrences(of: "-", with: "/")
                    .uppercased()
                let urlString = "https://resources.tidal.com/images/\(sanitized)/320x320.jpg"
                return URL(string: urlString)
            },
            originalBPM: bpm
        )
    }
}

private extension TIDALApiService.PlaylistResponse {
    func toPlaylist() -> Playlist {
        Playlist(
            id: uuid,
            name: title,
            trackCount: numberOfTracks
        )
    }
}
