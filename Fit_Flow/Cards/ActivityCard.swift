//
//  ActivityCard.swift
//  Fit_Flow
//
//  Created by Thrisha Kopula on 6/22/24.
//

import SwiftUI

struct ActivityCard: View {
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all) // Background color
            
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Spacer()
                        RoundedBox()
                            .frame(width: 150, height: 150)
                            .padding(.top, 20)
                            .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct RoundedBox: View {
    var body: some View {
        Color.blue
            .cornerRadius(20)
            .overlay(
                VStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red).padding()
                    Text(SpotifyView().bpm)
                        .foregroundColor(.white)
                        .bold()
                }
            )
    }
}
#Preview {
    ActivityCard()
}
