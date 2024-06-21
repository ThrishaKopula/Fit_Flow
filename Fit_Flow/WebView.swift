import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var webView: WKWebView?
    var didFinish: (WKWebView) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update the view if needed
    }

    func makeCoordinator() -> WebViewCoordinator {
        return WebViewCoordinator(didFinish: didFinish)
    }
}
