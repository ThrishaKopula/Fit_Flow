//import SwiftUI
//import SafariServices
//
//struct LoginView: View {
//    @StateObject private var spotifyService = SpotifyService.shared
//    @State private var authenticated = false
//    @State private var showingSafariView = false
//
//    var body: some View {
//        Group {
//            if authenticated {
//                ContentView()
//            } else {
//                Button(action: {
//                    initiateSpotifyLogin()
//                }) {
//                    Text("Login with Spotify")
//                        .padding()
//                        .background(Color.green)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//                .sheet(isPresented: $showingSafariView, onDismiss: {
//                    handleSpotifyLoginSuccess()
//                }) {
//                    if let url = spotifyService.getAuthorizationURL() {
//                        SafariView(url: url)
//                    }
//                }
//            }
//        }
//        .onAppear {
//            authenticated = spotifyService.authenticated
//        }
//    }
//
//    private func initiateSpotifyLogin() {
//        showingSafariView = true // Show the SafariView sheet for Spotify login
//    }
//
//    private func handleSpotifyLoginSuccess() {
//        print("in suceess")
//        spotifyService.login { success in
//            if success {
//                print("success")
//                authenticated = true // Update authenticated state
//                showingSafariView = false // Dismiss the SafariView sheet
//            }
//        }
//    }
//}
//
//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}
