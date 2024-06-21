import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var webView: WKWebView?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let webView = webView else { return }
        uiView.load(URLRequest(url: webView.url!))
    }

    func makeCoordinator() -> WebViewCoordinator {
        return WebViewCoordinator()
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var parent: LoginView?

    override init() {
        super.init()
    }

    convenience init(parent: LoginView) {
        self.init()
        self.parent = parent
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let urlString = webView.url?.absoluteString,
           urlString.starts(with: "https://thrishakopula.github.io/") {
            // Handle successful login
            print("success")
            LoginView().handleSpotifyLoginSuccess()
        }
    }
}
