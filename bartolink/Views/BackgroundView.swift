//
//  BackgroundView.swift
//  bartolink
//
//  Pastel-blauer Hintergrund.
//  Aktuell statisch — könnte später animierte Blobs bekommen.
//

import SwiftUI


struct BackgroundView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Theme.backgroundGradient(for: colorScheme)
            .ignoresSafeArea()
    }
}


#Preview {
    BackgroundView()
}
