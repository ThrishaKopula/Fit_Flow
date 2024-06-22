import Foundation
import Alamofire

class SpotifyService: ObservableObject {
    static let shared = SpotifyService()

    @Published var authenticated = false
    private let clientID = "1f65223760dc4f6db1fdd22c2cd3b44a"
    private let clientSecret = "c64a5f800a054ddba8a785021e4eb5c1"
    private let redirectURI = "https://thrishakopula.github.io/"
    private let tokenURL = "https://accounts.spotify.com/api/token"
    private let playlistsURL = "https://api.spotify.com/v1/me/playlists"
    private let tracksURL = "https://api.spotify.com/v1/playlists/{playlist_id}/tracks"
    private let trackDetailsURL = "https://api.spotify.com/v1/audio-features/{track_id}"
    private var accessToken: String?

    func login(completion: @escaping (Bool) -> Void) {
        guard let url = getAuthorizationURL() else {
            completion(false)
            return
        }

        // Present URL to user for Spotify login and handle redirect URI directly in WebViewCoordinator

        // For demo purposes, assuming login is successful and setting authenticated to true
        authenticated = true
        completion(true)
    }
    
    func getAuthorizationURL() -> URL? {
        print("in authorization")
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "playlist-read-private user-read-private")
        ]
        return components?.url
    }

    func getUserPlaylists(completion: @escaping ([Playlist]?) -> Void) {
        print("trying to get user playlists")
        guard let accessToken = accessToken else {
            print("in in here?")
            completion(nil)
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]

        AF.request(playlistsURL, headers: headers)
            .validate()
            .responseDecodable(of: PlaylistsResponse.self) { response in
                switch response.result {
                case .success(let playlistsResponse):
                    print("gottem!")
                    completion(playlistsResponse.items)
                case .failure(let error):
                    print("Error fetching playlists: \(error.localizedDescription)")
                    completion(nil)
                }
            }
    }


    func getPlaylistTracks(playlistID: String, completion: @escaping ([TrackItem]?) -> Void) {
        guard let accessToken = accessToken else {
            completion(nil)
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]

        let url = tracksURL.replacingOccurrences(of: "{playlist_id}", with: playlistID)

        AF.request(url, headers: headers)
            .validate()
            .responseDecodable(of: PlaylistTracksResponse.self) { response in
                switch response.result {
                case .success(let playlistTracksResponse):
                    completion(playlistTracksResponse.items)
                case .failure(let error):
                    print("Error fetching playlist tracks: \(error)")
                    completion(nil)
                }
            }
    }

    func getTrackDetails(trackID: String, completion: @escaping (TrackDetails?) -> Void) {
        guard let accessToken = accessToken else {
            completion(nil)
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]

        let url = trackDetailsURL.replacingOccurrences(of: "{track_id}", with: trackID)

        AF.request(url, headers: headers)
            .validate()
            .responseDecodable(of: TrackDetails.self) { response in
                switch response.result {
                case .success(let trackDetails):
                    completion(trackDetails)
                case .failure(let error):
                    print("Error fetching track details: \(error)")
                    completion(nil)
                }
            }
    }
}

// Define Playlist, TrackItem, and Track structs as needed

struct Playlist: Decodable {
    let id: String
    let name: String
}

struct TrackItem: Decodable {
    let track: Track
}

struct Track: Decodable {
    let id: String
    let name: String
}

struct TrackDetails: Decodable {
    let tempo: Double?
}

// Define PlaylistsResponse structure
struct PlaylistsResponse: Decodable {
    let items: [Playlist]
}

// Define PlaylistTracksResponse structure
struct PlaylistTracksResponse: Decodable {
    let items: [TrackItem]
}
