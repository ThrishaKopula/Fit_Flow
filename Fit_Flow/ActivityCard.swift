//
//  ActivityCard.swift
//  Fit_Flow
//
//  Created by Thrisha Kopula on 6/21/24.
//

import SwiftUI

struct ActivityCard: View {
    var body: some View {
       
        ZStack {
            Color(uiColor: .systemGray6).cornerRadius(15)
            
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("BPM").font(.system(size: 20))
                    }
                    Spacer()
                    Image(systemName: "heart.fill").foregroundColor(.red)
                }
                .padding()
                Text("75").font(.system(size: 24))
            }
            .padding()
        }
    }
}

#Preview {
    ActivityCard()
}
