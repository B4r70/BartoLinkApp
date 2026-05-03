//
//  SLKeyValue.swift
//  bartolink
//
//  Zeile mit Key links und Value rechts; hairline-Bottom-Border.
//  In `last`-Zeilen wird die Linie unterdrückt.
//

import SwiftUI


struct SLKeyValue: View {

    let key: String
    let value: String
    var mono: Bool = false
    var last: Bool = false

    var body: some View {
        HStack {
            Text(key)
                .font(.system(size: 14))
                .foregroundStyle(Theme.ink2)
            Spacer(minLength: 12)
            Text(value)
                .font(
                    mono
                    ? .system(size: 12.5, design: .monospaced)
                    : .system(size: 14, weight: .medium)
                )
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if !last {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
            }
        }
    }
}


#Preview {
    SLCard {
        VStack(spacing: 0) {
            SLLabel("App")
            SLKeyValue(key: "Bundle-ID", value: "cloud.barto.bartolink", mono: true)
            SLKeyValue(key: "Version", value: "1.4.0 (220)")
            SLKeyValue(key: "APNs-Env", value: "production", last: true)
        }
    }
    .padding()
    .background(Color(red: 0.85, green: 0.93, blue: 1.0))
}
