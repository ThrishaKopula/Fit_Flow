import SwiftUI
import WebKit

struct SpotifyView: View {
    @State private var showWebView = true
    @State private var playlists: [String] = []
    @State public var bpm: String = "Fetching BPM..."

    var body: some View {
        VStack {
            if showWebView {
                WebViewWrapper()
                    .onReceive(NotificationCenter.default.publisher(for: .didReceiveSpotifyToken)) { _ in
                        fetchPlaylists()
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
//                List(playlists, id: \.self) { playlist in
//                    Text(playlist)
//                }
            }
        }
        .onAppear {
            HealthManager.shared.fetchHeartRate { rate in
                DispatchQueue.main.async {
                    self.bpm = "\(Int(rate ?? 0)) BPM"
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
        showWebView = false
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

//struct ActivityCard: View {
//    var body: some View {
//        ZStack {
//            Color.white.edgesIgnoringSafeArea(.all) // Background color
//            
//            GeometryReader { geometry in
//                VStack {
//                    HStack {
//                        Spacer()
//                        RoundedBox()
//                            .frame(width: 150, height: 150)
//                            .padding(.top, 20)
//                            .padding(.trailing, 20)
//                    }
//                    Spacer()
//                }
//            }
//        }
//    }
//}

struct RoundedBox: View {
    var body: some View {
        Color.blue
            .cornerRadius(20)
            .overlay(
                VStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red).padding()
                    Text(SpotifyView().bpm)
                        .foregroundColor(.white)
                        .bold()
                }
            )
    }
}

#Preview {
    SpotifyView()
}

