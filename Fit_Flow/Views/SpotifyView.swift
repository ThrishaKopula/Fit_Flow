import SwiftUI
import WebKit
import Alamofire

struct SpotifyView: View {
    @State private var showWebView = true
    @State private var playlists: [Playlist] = []
    @State private var tracksWithTempo: [String: TrackDetails] = [:] // Track ID -> TrackWithTempo
    @State public var bpm: String = "Fetching BPM..."

    var body: some View {
        VStack {
            if showWebView {
                WebViewWrapper()
                    .onReceive(NotificationCenter.default.publisher(for: .didReceiveSpotifyToken)) { _ in
                        print("Received Spotify token notification")
                        fetchAllTracksWithTempo()
                    }
            } else {
                ZStack {
                    Color.white.edgesIgnoringSafeArea(.all) // Background color
                    
                    GeometryReader { geometry in
                        VStack {
                            HStack {
                                Spacer()
                                // RoundedBox directly within the VStack
                                Color(uiColor: .systemGray6)
                                    .cornerRadius(20)
                                    .shadow(radius: 5)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "heart.fill")
                                                .foregroundColor(.red)
                                                .padding()
                                                .font(.system(size: 40))
                                            Text(bpm)
                                                .foregroundColor(.black)
                                                .bold()
                                                .font(.system(size: 30))
                                        }
                                    )
                                    .frame(width: 150, height: 150)
                                    .padding(.top, 20)
                                    .padding(.trailing, 20)
                            }
                            Spacer()
                        }
                    }
                }
                List(tracksWithTempo.values.sorted(by: { $0.name < $1.name }), id: \.name) { TrackDetails in
                    Text("\(TrackDetails.name) - \(TrackDetails.tempo) BPM")
                }
            }
        }
        .onAppear {
            HealthManager.shared.fetchHeartRate { rate in
                DispatchQueue.main.async {
                    self.bpm = "\(Int(rate ?? 0)) BPM"
                    print("Heart rate fetched: \(self.bpm)")
                }
            }
        }
    }

    func fetchAllTracksWithTempo() {
        print("Fetching all tracks with tempo")
        SpotifyService.shared.getUserPlaylists { playlists in
            guard let playlists = playlists else {
                print("Failed to fetch playlists")
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var allTracks: [Track] = []
            var processedTrackIDs: Set<String> = []
            
            for playlist in playlists {
                dispatchGroup.enter()
                print("Fetching tracks for playlist!!: \(playlist.name)")
                SpotifyService.shared.getPlaylistTracks(playlistID: playlist.id) { tracks in
                    if let tracks = tracks {
                        for track in tracks {
                            if !processedTrackIDs.contains(track.id) {
                                allTracks.append(track)
                                processedTrackIDs.insert(track.id)
                                print("Added track: \(track.name)")
                            }
                        }
                    } else {
                        print("Failed to fetch tracks for playlist: \(playlist.name)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                print("Fetched all tracks from playlists, total unique tracks: \(allTracks.count)")
                self.fetchTrackDetailsForTracks(tracks: allTracks)
            }
        }
        showWebView = false
    }

    private func fetchTrackDetailsForTracks(tracks: [Track]) {
        let dispatchGroup = DispatchGroup()
        
        for track in tracks {
            dispatchGroup.enter()
            print("Fetching details for track: \(track.name)")
            SpotifyService.shared.getTrackDetails(trackID: track.id) { trackDetails in
                if let trackDetails = trackDetails {
                    DispatchQueue.main.async {
                        self.tracksWithTempo[track.id] = TrackDetails(id: track.id, name: track.name, tempo: trackDetails.tempo)
                        print("Track: \(track.name), Tempo: \(trackDetails.tempo)")
                    }
                } else {
                    print("Failed to fetch details for track: \(track.name)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("All tracks and their tempos fetched successfully.")
            print("Total number of tracks: \(self.tracksWithTempo.count)")
        }
    }
}

struct WebViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        if let url = SpotifyService.shared.getAuthorizationURL() {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewWrapper

        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            if url.absoluteString.starts(with: "https://thrishakopula.github.io/") {
                if let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value {
                    SpotifyService.shared.exchangeCodeForToken(code: code) { success in
                        print("Spotify token exchange success: \(success)")
                        NotificationCenter.default.post(name: .didReceiveSpotifyToken, object: nil)
                    }
                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}



#Preview {
    SpotifyView()
}
