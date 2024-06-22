import UIKit

//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("Received URL: \(url.absoluteString)")
        if url.scheme == "https" {
            if let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "code" })?.value {
                SpotifyService.shared.exchangeCodeForToken(code: code) { success in
                    if success {
                        print("exchanged code in app delegate")
                        NotificationCenter.default.post(name: .didReceiveSpotifyToken, object: nil)
                    } else {
                        print("Failed to exchange code for token")
                    }
                }
            }
            return true
        }
        return false
    }
}

extension Notification.Name {
    static let didReceiveSpotifyToken = Notification.Name("didReceiveSpotifyToken")
}
