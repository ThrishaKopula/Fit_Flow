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
            URLQueryItem(name: "scope", value: "playlist-read-private user-read-private user-modify-playback-state")
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
//                print("Fetched playlists: \(playlists.map { $0.name })")
                completion(playlists)
            case .failure(let error):
                print("Failed to fetch playlists: \(error)")
                completion(nil)
            }
        }
    }

    func getPlaylistTracks(playlistID: String, completion: @escaping ([PlaylistTrackObject]?) -> Void) {
        print("im in here")
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
                completion(tracksResponse.items)
            case .failure(let error):
                print("Failed to fetch tracks: \(error)")
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
                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                completion(nil)
            }
        }
    }
    
}

struct PlaylistsResponse: Codable {
    let items: [PlaylistItem]
}

struct PlaylistItem: Codable {
    let id: String
    let name: String
}

struct Playlist {
    let id: String
    let name: String
}

struct TracksResponse: Codable {
    let items: [PlaylistTrackObject]
}

struct PlaylistTrackObject: Codable {
    let track: Track
}

struct Track: Codable {
//    let track: TrackObject
    let id: String
    let name: String
}

struct TrackDetails: Codable {
    let tempo: Double?
    let id: String?
}


struct PlaybackStateResponse: Decodable {
    let device: Device
    let item: Track
    let actions: StateActions
}

struct StateActions: Decodable {
    let disallows: [String: Bool]
    
    var pausing: Bool {
        return disallows["pausing"] ?? false
    }
    
    var skippingNext: Bool {
        return disallows["skipping_next"] ?? false
    }
    
    var skippingPrev: Bool {
        return disallows["skipping_prev"] ?? false
    }
}

struct Device: Codable {
    let id: String
    let is_active: Bool
    let is_private_session: Bool
    let is_restricted: Bool
    let name: String
    let type: String
    let volume_percent: Int
    let supports_volume: Bool
}


