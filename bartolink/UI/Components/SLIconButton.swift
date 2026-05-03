//
//  SLIconButton.swift
//  bartolink
//
//  Runder 36×36 Glasknopf mit SF-Symbol. Optionaler Tap-Handler.
//

import SwiftUI


struct SLIconButton: View {

    let systemName: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink2)
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .background(.ultraThinMaterial, in: Circle())
                }
                .overlay {
                    Circle().strokeBorder(Theme.hairline, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    HStack(spacing: 8) {
        SLIconButton(systemName: "magnifyingglass")
        SLIconButton(systemName: "ellipsis")
    }
    .padding()
    .background(Color(red: 0.85, green: 0.93, blue: 1.0))
}
