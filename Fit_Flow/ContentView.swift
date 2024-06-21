import SwiftUI
import WebKit
import Alamofire

import SwiftUI

struct ContentView: View {
    @StateObject private var spotifyService = SpotifyService.shared
    @StateObject private var healthManager = HealthManager()
    @State private var playlistsText = ""
    @State private var heartRateText = ""

    var body: some View {
        VStack {
            Text(playlistsText)
                .padding()

            Text(heartRateText)
                .padding()
        }
        .onAppear {
            fetchPlaylists()
            fetchHeartRate()
        }
    }

    private func fetchPlaylists() {
        spotifyService.getUserPlaylists { playlists in
            if let playlists = playlists, let firstPlaylist = playlists.first {
                fetchTracksAndBPM(for: firstPlaylist.id)
            } else {
                playlistsText = "Failed to fetch playlists"
            }
        }
    }

    private func fetchTracksAndBPM(for playlistID: String) {
        spotifyService.getPlaylistTracks(playlistID: playlistID) { tracks in
            if let tracks = tracks {
                var formattedText = "Playlist:\n\n"
                let group = DispatchGroup()
                for track in tracks {
                    group.enter()
                    spotifyService.getTrackDetails(trackID: track.track.id) { trackDetails in
                        if let trackDetails = trackDetails {
                            formattedText += "\(track.track.name) - BPM: \(trackDetails.tempo ?? 0)\n"
                        } else {
                            formattedText += "Failed to fetch track details\n"
                        }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    playlistsText = formattedText
                }
            } else {
                playlistsText = "Failed to fetch tracks"
            }
        }
    }

    private func fetchHeartRate() {
        healthManager.fetchHeartRate { heartRate in
            if let heartRate = heartRate {
                heartRateText = "Current Heart Rate: \(heartRate) bpm"
            } else {
                heartRateText = "Failed to fetch heart rate"
            }
        }
    }
}
