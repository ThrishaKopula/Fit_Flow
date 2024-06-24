import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
//            Image("FitFlow")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: 300, height: 300)
//                .padding()
            
            NavigationView {
                NavigationLink(destination: SpotifyView()) {
                    Text("Get Started")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    
                }
                .navigationTitle("")
                
            }
            
        }
        .padding()
        .background(Color(#colorLiteral(red: 0.92156, green: 0.96, blue: 0.9333, alpha: 1.0))) // Set background color for the VStack content
        .edgesIgnoringSafeArea(.all) // Extend color to all edges
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
