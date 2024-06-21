import SwiftUI

struct ContentView: View {
    @StateObject private var spotifyService = SpotifyService.shared
    @State private var playlistsText = ""
    @State private var bpmText = ""

    var body: some View {
        VStack {
            Text(playlistsText)
                .padding()
            Text(bpmText)
                .padding()
        }
        .onAppear {
            spotifyService.getUserPlaylists { playlists in
                if let playlists = playlists, let firstPlaylist = playlists.first {
                    fetchTracksAndBPM(for: firstPlaylist.id)
                } else {
                    playlistsText = "Failed to fetch playlists"
                }
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
}
