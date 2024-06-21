//
//  LoginView.swift
//  Fit_Flow
//
//  Created by Thrisha Kopula on 6/21/24.
//

import SwiftUI
import WebKit

struct LoginView: View {
    @StateObject private var spotifyService = SpotifyService.shared
    @State private var webView: WKWebView?
    @State private var authenticated = false

    var body: some View {
        Group {
            if authenticated {
                NavigationLink(destination: ContentView(), isActive: $authenticated) {
                    EmptyView()
                }
                .hidden()
            } else if webView != nil {
                WebView(webView: $webView, didFinish: handleWebViewFinishedLoading)
            } else {
                Button(action: {
                    initiateSpotifyLogin()
                }) {
                    Text("Login with Spotify")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .onAppear {
            // Check if user is already authenticated
            authenticated = spotifyService.authenticated
        }
    }

    private func initiateSpotifyLogin() {
        guard let url = spotifyService.getAuthorizationURL() else { return }
        webView = WKWebView()
        webView?.navigationDelegate = WebViewCoordinator()
        webView?.load(URLRequest(url: url))
    }

    private func handleWebViewFinishedLoading(_ webView: WKWebView) {
        guard let urlString = webView.url?.absoluteString else { return }
        if urlString.starts(with: "https://thrishakopula.github.io/") {
            // Handle successful login
            handleSpotifyLoginSuccess()
        }
    }
    
    func handleSpotifyLoginSuccess() {
        authenticated = true
        webView = nil // Remove the web view after successful login
    }
}
