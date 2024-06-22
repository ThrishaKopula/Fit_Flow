import SwiftUI
import WebKit

struct SpotifyView: View {
    @State private var showWebView = true
    @State private var playlists: [String] = []
    @State private var bpm: String = "Fetching BPM..."

    var body: some View {
        VStack {
            if showWebView {
                WebViewWrapper()
                    .onReceive(NotificationCenter.default.publisher(for: .didReceiveSpotifyToken)) { _ in
                        fetchPlaylists()
                    }
            } else {
                List(playlists, id: \.self) { playlist in
                    Text(playlist)
                }
                Text(bpm)
                    .font(.largeTitle)
                    .padding()
            }
        }
        .onAppear {
            HealthManager.shared.fetchHeartRate { rate in
                DispatchQueue.main.async {
                    self.bpm = "\(Int(rate ?? 0)) bpm"
                }
            }
        }
    }

    func fetchPlaylists() {
        SpotifyService.shared.getUserPlaylists { playlists in
            DispatchQueue.main.async {
                self.playlists = playlists?.map { $0.name } ?? ["Failed to fetch playlists"]
            }
        }
    }
}

struct WebViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        print("in hereeee")
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
                print(url.absoluteString)
                if let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value {
                    SpotifyService.shared.exchangeCodeForToken(code: code) { success in
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
