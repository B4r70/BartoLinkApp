//
//  SLChip.swift
//  bartolink
//
//  Capsule mit Dot + Text. Color-mix-Hintergrund (oder gefüllt).
//

import SwiftUI


struct SLChip: View {

    let text: String
    var color: Color = Theme.accentBlue
    var filled: Bool = false
    var dot: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            if dot {
                Circle()
                    .fill(filled ? Color.white : color)
                    .frame(width: 6, height: 6)
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.2)
        }
        .foregroundStyle(filled ? Color.white : color)
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background {
            Capsule(style: .continuous)
                .fill(filled ? color : color.tinted(0.15))
        }
        .overlay {
            if !filled {
                Capsule(style: .continuous)
                    .strokeBorder(color.opacity(0.30), lineWidth: 1)
            }
        }
    }
}


#Preview {
    VStack(spacing: 10) {
        SLChip(text: "Verspätet · +7 Min", color: Theme.accentAmber)
        SLChip(text: "Pünktlich", color: Theme.accentGreen)
        SLChip(text: "Healthy", color: Theme.accentGreen, filled: true)
        SLChip(text: "Severity · Hoch", color: Theme.accentAmber, dot: false)
    }
    .padding()
    .background(Color(red: 0.85, green: 0.93, blue: 1.0))
}
