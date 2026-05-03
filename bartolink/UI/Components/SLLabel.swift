//
//  SLLabel.swift
//  bartolink
//
//  Eyebrow-Label (uppercase, 12 pt semibold).
//

import SwiftUI


struct SLLabel: View {

    let text: String
    var color: Color = Theme.ink3

    init(_ text: String, color: Color = Theme.ink3) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}


#Preview {
    VStack(alignment: .leading, spacing: 8) {
        SLLabel("Sonntag · 03 Mai")
        SLLabel("System · Live", color: Theme.ink2)
        SLLabel("● Alle Systeme nominal", color: Theme.accentGreen)
    }
    .padding()
    .background(Color(red: 0.85, green: 0.93, blue: 1.0))
}
