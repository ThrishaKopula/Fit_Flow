import SwiftUI

struct ContentView: View {
    @State private var isActive: Bool = false
    
    var body: some View {
        ZStack {
            Color("bkColor").ignoresSafeArea()
            
            VStack {
                Spacer() // Top Spacer to push content to the top edge
                
                Image("FitFlow")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                
                Button(action: {
                    isActive = true
                }) {
                    Text("Get Started")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color("buttonColor"))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(radius: 3)
                }
                .fullScreenCover(isPresented: $isActive, content: {
                    SpotifyView()
                })
                
                Spacer() // Bottom Spacer to push content to the bottom edge
            }
            .padding()
            .background(Color(#colorLiteral(red: 0.92156, green: 0.96, blue: 0.9333, alpha: 1.0))) // Set background color for the VStack content
            .edgesIgnoringSafeArea(.all) // Extend color to all edges
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
