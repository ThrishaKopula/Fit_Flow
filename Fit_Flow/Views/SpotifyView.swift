import SwiftUI
import WebKit
import Alamofire

struct SpotifyView: View {
    @State private var showWebView = true
    @State private var playlists: [Playlist] = []
    @State private var tracksWithTempo: [String: Double] = [:] // Track ID -> TrackWithTempo
    @State public var bpm: String = "Fetching BPM..."

    var body: some View {

        VStack {
            if showWebView {
                WebViewWrapper()
                    .onReceive(NotificationCenter.default.publisher(for: .didReceiveSpotifyToken)) { _ in
                        print("Received Spotify token notification")
//                        fetchAllTracksWithTempo()
                        didReceiveSpotifyToken()
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
                List(tracksWithTempo.sorted(by: { $0.key < $1.key }), id: \.key) { trackID, tempo in
                    Text("\(trackID) - \(tempo) BPM")
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
    
    
    func didReceiveSpotifyToken() {
        // Fetch user playlists
        SpotifyService.shared.getUserPlaylists { playlists in
            guard let playlists = playlists else {
                DispatchQueue.main.async {
                    // Handle the case where playlists could not be fetched
                    print("Failed to fetch playlists")
                }
                return
            }

            DispatchQueue.main.async {
                if playlists.isEmpty {
                    // Handle the case where no playlists are available
                    print("No playlists found")
                    return
                }

                // Create a dispatch group to wait for all fetch operations
                let group = DispatchGroup()

                for playlist in playlists {
                    group.enter()
                    self.fetchTracksAndBPM(for: playlist.id) {
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    // All fetch operations are complete
                    print("Fetched tracks for all playlists.")
                    // Perform any further UI updates or actions here
                }
            }
        }
    }


    
    
    private func fetchTracksAndBPM(for playlistID: String, completion: @escaping () -> Void) {
        SpotifyService.shared.getPlaylistTracks(playlistID: playlistID) { tracks in
            guard let tracks = tracks else {
                print("Failed to fetch tracks")
                completion()
                return
            }

            let group = DispatchGroup()

            for track in tracks {
                group.enter()
                SpotifyService.shared.getTrackDetails(trackID: track.track.id) { trackDetails in
                    if let trackDetails = trackDetails {
                        print("\(track.track.name) - BPM: \(trackDetails.tempo)")
                    } else {
                        print("Failed to fetch track details for \(track.track.name)\n")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                // Here you can use formattedText for UI updates, like assigning to a label or text view.
                // e.g., self.yourLabel.text = formattedText
                print("All track details have been fetched for playlist \(playlistID).")
                completion()
            }
        }
        showWebView = false
    }




    
    
    

//    func fetchAllTracksWithTempo() {
//        print("Fetching all tracks with tempo")
//        SpotifyService.shared.getUserPlaylists { playlists in
//            guard let playlists = playlists else {
//                print("Failed to fetch playlists")
//                return
//            }
//            
//            let dispatchGroup = DispatchGroup()
////            var allTracks: [TrackItem] = []
//            var processedTrackIDs: Set<String> = []
//            
//            for playlist in playlists {
//                dispatchGroup.enter()
//                print("Fetching tracks for playlist!!: \(playlist.name)")
//                SpotifyService.shared.getPlaylistTracks(playlistID: playlist.id) { tracks in
//                    if let tracks = tracks {
//                        DispatchQueue.main.async {
//                            
//                       
//                            for track in tracks {
//                                
//                                    fetchTrackDetailsForTrack(trackID: track.track.id)
//            
//                            }
//                        }
//                    } else {
//                        print("Failed to fetch tracks for playlist: \(playlist.name)")
//                    }
//                    dispatchGroup.leave()
//                }
//            }
//            
//            dispatchGroup.notify(queue: .main) {
////                print("Fetched all tracks from playlists, total unique tracks: \(allTracks.count)")
////                self.fetchTrackDetailsForTrack(tracks: allTracks)
//            }
//        }
//        showWebView = false
//    }

//    private func fetchTrackDetailsForTrack(trackID: String) {
//        let dispatchGroup = DispatchGroup()
//        
//        dispatchGroup.enter()
////            print("Fetching details for track: \(track.name)")
//        SpotifyService.shared.getTrackDetails(trackID: trackID) { trackDetails in
//            if let trackDetails = trackDetails {
//                DispatchQueue.main.async {
//                    self.tracksWithTempo[trackID] = trackDetails.tempo
//                    print("Track: \(trackID), Tempo: \(trackDetails.tempo)")
//                }
//            } else {
//                print("Failed to fetch details for track: \(trackID)")
//            }
//            dispatchGroup.leave()
//        }
//        
//        dispatchGroup.notify(queue: .main) {
//            print("All tracks and their tempos fetched successfully.")
//            print("Total number of tracks: \(self.tracksWithTempo.count)")
//        }
//    }
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
