//
//  SLCard.swift
//  bartolink
//
//  Glaskarte mit optionalem Akzent-Streifen links und optionalem Top-Verlauf.
//

import SwiftUI


struct SLCard<Content: View>: View {

    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 18
    var accent: Color? = nil
    var topTint: Color? = nil          // optionaler Verlauf von oben
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            shape
                .fill(Theme.cardFill)
                .background(.ultraThinMaterial, in: shape)

            if let topTint {
                shape
                    .fill(
                        LinearGradient(
                            colors: [topTint.tinted(0.18), Theme.cardFill],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            }

            content()
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)

        }
        .overlay {
            shape.strokeBorder(Theme.cardStroke, lineWidth: 1)
        }
        .overlay(alignment: .leading) {
            if let accent {
                Capsule()
                    .fill(accent)
                    .frame(width: 3)
                    .padding(.vertical, 16)
            }
        }
        .clipShape(shape)
        .shadow(color: Theme.cardShadow, radius: 18, x: 0, y: 6)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}


#Preview {
    VStack(spacing: 12) {
        SLCard {
            Text("Standard-Karte")
                .font(.system(size: 16, weight: .semibold))
        }

        SLCard(accent: Theme.accentAmber) {
            VStack(alignment: .leading, spacing: 8) {
                SLLabel("Grund")
                Text("Weichenstörung")
                    .font(.system(size: 20, weight: .semibold))
            }
        }

        SLCard(topTint: Theme.accentGreen) {
            VStack(alignment: .leading, spacing: 8) {
                SLLabel("● Alle Systeme nominal", color: Theme.accentGreen)
                Text("99,8% Uptime").font(.system(size: 36, weight: .bold))
            }
        }
    }
    .padding(20)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.85, green: 0.93, blue: 1.00),
                Color(red: 0.72, green: 0.85, blue: 0.98),
            ],
            startPoint: .top, endPoint: .bottom
        )
    )
}
