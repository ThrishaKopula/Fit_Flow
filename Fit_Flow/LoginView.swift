import SwiftUI
import WebKit

struct LoginView: View {
    @StateObject private var spotifyService = SpotifyService.shared
    @State private var webView: WKWebView?
    @State private var authenticated = false
    @State private var webViewCoordinator: WebViewCoordinator?

    var body: some View {
        Group {
            NavigationLink(
                destination: ContentView(),
                isActive: $authenticated,
                label: {
                    EmptyView()
                }
            )
            .hidden()

            if webView != nil {
                WebView(webView: $webView, didFinish: handleWebViewFinishedLoading)
            } else {
                Button(action: {
                    initiateSpotifyLogin()
                }) {
                    Text("Login with Spotify")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .sheet(isPresented: .constant(true)) {
                    if let url = spotifyService.getAuthorizationURL() {
                        SafariView(url: url)
                    }
                }
            }
        }
        .onAppear {
            authenticated = spotifyService.authenticated
        }
    }

    private func initiateSpotifyLogin() {
        guard let url = spotifyService.getAuthorizationURL() else { return }
        webView = WKWebView()
        webViewCoordinator = WebViewCoordinator(didFinish: handleWebViewFinishedLoading)
        webView?.navigationDelegate = webViewCoordinator
        webView?.load(URLRequest(url: url))
    }

    private func handleWebViewFinishedLoading(_ webView: WKWebView) {
        guard let urlString = webView.url?.absoluteString else { return }
        if urlString.starts(with: "https://thrishakopula.github.io/") {
            handleSpotifyLoginSuccess()
        }
    }

    private func handleSpotifyLoginSuccess() {
        spotifyService.login { success in
            if success {
                authenticated = true
                webView = nil
                webViewCoordinator = nil
            }
        }
    }
}
