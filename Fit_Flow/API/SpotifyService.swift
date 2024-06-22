import Foundation
import Alamofire

class SpotifyService {
    static let shared = SpotifyService()
    private let clientID = "1f65223760dc4f6db1fdd22c2cd3b44a"
    private let clientSecret = "c64a5f800a054ddba8a785021e4eb5c1"
    private let redirectURI = "https://thrishakopula.github.io/"
    private let tokenURL = "https://accounts.spotify.com/api/token"
    private let playlistsURL = "https://api.spotify.com/v1/me/playlists"
    private let tracksURL = "https://api.spotify.com/v1/playlists/{playlist_id}/tracks"
    private let trackDetailsURL = "https://api.spotify.com/v1/audio-features/{track_id}"

    var accessToken: String?

    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "playlist-read-private user-read-private")
        ]
        return components?.url
    }

    func exchangeCodeForToken(code: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: tokenURL) else {
            print("Invalid token URL")
            completion(false)
            return
        }
        
        let parameters: [String: Any] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "client_secret": clientSecret
        ]
        
        AF.request(url, method: .post, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let data):
                if let json = data as? [String: Any], let accessToken = json["access_token"] as? String {
                    self.accessToken = accessToken
                    print("Access token fetched: \(accessToken)")
                    completion(true)
                } else {
                    print("Failed to parse access token")
                    completion(false)
                }
            case .failure(let error):
                print("Token exchange request failed with error: \(error)")
                completion(false)
            }
        }
    }

    func getUserPlaylists(completion: @escaping ([Playlist]?) -> Void) {
        guard let accessToken = accessToken else {
            print("No access token available")
            completion(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        AF.request(playlistsURL, headers: headers).responseDecodable(of: PlaylistsResponse.self) { response in
            switch response.result {
            case .success(let playlistsResponse):
                let playlists = playlistsResponse.items.map { Playlist(id: $0.id, name: $0.name) }
                print("Fetched playlists: \(playlists.map { $0.name })")
                completion(playlists)
            case .failure(let error):
                print("Failed to fetch playlists: \(error)")
                completion(nil)
            }
        }
    }

    func getPlaylistTracks(playlistID: String, completion: @escaping ([Track]?) -> Void) {
        guard let accessToken = accessToken else {
            print("No access token available")
            completion(nil)
            return
        }
        
        let url = tracksURL.replacingOccurrences(of: "{playlist_id}", with: playlistID)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        AF.request(url, headers: headers).responseDecodable(of: TracksResponse.self) { response in
            switch response.result {
            case .success(let tracksResponse):
                let tracks = tracksResponse.items.map { Track(id: $0.track.id, name: $0.track.name) }
                print("Fetched tracks for playlist \(playlistID): \(tracks.map { $0.name })")
                completion(tracks)
            case .failure(let error):
                print("Failed to fetch tracks: \(error)")
                completion(nil)
            }
        }
    }

    func getTrackDetails(trackID: String, completion: @escaping (TrackDetails?) -> Void) {
        guard let accessToken = accessToken else {
            print("No access token available")
            completion(nil)
            return
        }
        
        let url = trackDetailsURL.replacingOccurrences(of: "{track_id}", with: trackID)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        AF.request(url, headers: headers).responseDecodable(of: TrackDetails.self) { response in
            switch response.result {
            case .success(let trackDetails):
                print("Fetched track details for \(trackID): tempo \(trackDetails.tempo)")
                completion(trackDetails)
            case .failure(let error):
                print("Failed to fetch track details: \(error)")
                completion(nil)
            }
        }
    }
}
struct Playlist {
    let id: String
    let name: String
}

struct Track {
    let id: String
    let name: String
}

struct PlaylistsResponse: Codable {
    let items: [PlaylistItem]
}

struct PlaylistItem: Codable {
    let id: String
    let name: String
}

struct TracksResponse: Codable {
    let items: [TrackItem]
}

struct TrackItem: Codable {
    let track: TrackDetails
}

struct TrackDetails: Codable {
    let id: String
    let name: String
    let tempo: Double
}
