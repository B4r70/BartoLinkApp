//
//  SLKPI.swift
//  bartolink
//
//  KPI-Block für 3-Spalten-Grids in Karten.
//  Trennlinie links wird über `divider` ein-/ausgeschaltet.
//

import SwiftUI


struct SLKPI: View {

    let label: String
    let value: String
    var sub: String? = nil
    var valueColor: Color = Theme.ink
    var divider: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            if divider {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 1)
            }
            VStack(alignment: .leading, spacing: 4) {
                SLLabel(label)
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(valueColor)
                if let sub {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.ink3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


#Preview {
    SLCard(padding: 0) {
        HStack(spacing: 0) {
            SLKPI(label: "Linie", value: "RB23", sub: "Nr. 12614")
            SLKPI(label: "Gleis", value: "1", sub: "Bad Ems", divider: true)
            SLKPI(label: "Verspätung", value: "+7", sub: "Minuten",
                  valueColor: Theme.accentAmber, divider: true)
        }
    }
    .padding()
    .background(Color(red: 0.85, green: 0.93, blue: 1.0))
}
