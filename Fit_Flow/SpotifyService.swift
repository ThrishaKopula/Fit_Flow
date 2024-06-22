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
                    completion(true)
                } else {
                    completion(false)
                }
            case .failure:
                completion(false)
            }
        }
    }

    func getUserPlaylists(completion: @escaping ([Playlist]?) -> Void) {
        guard let accessToken = accessToken else {
            completion(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        AF.request(playlistsURL, headers: headers).responseDecodable(of: PlaylistsResponse.self) { response in
            switch response.result {
            case .success(let playlistsResponse):
                completion(playlistsResponse.items)
            case .failure:
                completion(nil)
            }
        }
    }

    func getPlaylistTracks(playlistID: String, completion: @escaping ([Track]?) -> Void) {
        guard let accessToken = accessToken else {
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
                completion(tracksResponse.items.map { $0.track })
            case .failure:
                completion(nil)
            }
        }
    }

    func getTrackDetails(trackID: String, completion: @escaping (TrackDetails?) -> Void) {
        guard let accessToken = accessToken else {
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
                completion(trackDetails)
            case .failure:
                completion(nil)
            }
        }
    }
}

struct PlaylistsResponse: Decodable {
    let items: [Playlist]
}

struct Playlist: Decodable {
    let id: String
    let name: String
}

struct TracksResponse: Decodable {
    let items: [TrackItem]
}

struct TrackItem: Decodable {
    let track: Track
}

struct Track: Decodable {
    let id: String
    let name: String
    let artists: [Artist]
}

struct Artist: Decodable {
    let name: String
}

struct TrackDetails: Decodable {
    let tempo: Double
}
