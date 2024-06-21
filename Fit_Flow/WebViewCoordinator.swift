import WebKit

class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var didFinish: (WKWebView) -> Void

    init(didFinish: @escaping (WKWebView) -> Void) {
        self.didFinish = didFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinish(webView)
    }
}
