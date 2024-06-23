import SwiftUI
import WebKit
import Alamofire

struct SpotifyView: View {
    @State private var showWebView = true
    @State private var playlists: [Playlist] = []
    @State private var tracksWithTempo: [String: Double] = [:]
    @State public var bpm: String = "Fetching BPM..."

    var body: some View {
        VStack {
            if showWebView {
                WebViewWrapper()
                    .onReceive(NotificationCenter.default.publisher(for: .didReceiveSpotifyToken)) { _ in
                        print("Received Spotify token notification")
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

    //fetches for all the playlists
    func didReceiveSpotifyToken() {
        SpotifyService.shared.getUserPlaylists { playlists in
            guard let playlists = playlists else {
                DispatchQueue.main.async {
                    print("Failed to fetch playlists")
                }
                return
            }

            DispatchQueue.main.async {
                if playlists.isEmpty {
                    print("No playlists found")
                    return
                }

                let group = DispatchGroup()

                for playlist in playlists {
                    group.enter()
                    fetchTracksAndBPM(for: playlist.id) {
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
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
                fetchTrackDetails(trackID: track.track.id) { tempo in
                    if let tempo = tempo {
                        DispatchQueue.main.async {
                            self.tracksWithTempo[track.track.name] = tempo
                            print("Track Name: \(track.track.name), Tempo: \(tempo)")
                        }
                    } else {
                        print("Failed to fetch track details for \(track.track.name)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                print("All track details have been fetched for playlist \(playlistID).")
                DispatchQueue.main.async {
                    self.showWebView = false
                }
                completion()
            }
        }
    }

    private func fetchTrackDetails(trackID: String, completion: @escaping (Double?) -> Void) {
        SpotifyService.shared.getTrackDetails(trackID: trackID) { trackDetails in
            guard let trackDetails = trackDetails else {
                completion(nil)
                return
            }
            completion(trackDetails.tempo)
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
