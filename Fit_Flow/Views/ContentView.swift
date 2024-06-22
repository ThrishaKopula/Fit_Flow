import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: SpotifyView()) {
                    Text("Get Started")
                        .font(.title)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
//                NavigationLink(destination: HealthKitView()) {
//                    Text("Health Data")
//                        .font(.title)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
