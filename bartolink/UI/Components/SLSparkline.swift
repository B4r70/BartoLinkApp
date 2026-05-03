//
//  SLSparkline.swift
//  bartolink
//
//  Lightweight Sparkline — Path mit Stroke + LinearGradient-Fill darunter.
//  Bei Erscheinen wird der Strich animiert "gezeichnet".
//

import SwiftUI


struct SLSparkline: View {

    let values: [CGFloat]
    var color: Color = Theme.accentGreen

    @State private var trim: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let path = linePath(in: geo.size)
            let fill = fillPath(in: geo.size)

            ZStack {
                fill.fill(
                    LinearGradient(
                        colors: [color.opacity(0.35), color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                path.trim(from: 0, to: trim)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.1)) { trim = 1 }
            }
        }
    }

    private func linePath(in size: CGSize) -> Path {
        guard values.count > 1 else { return Path() }

        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let range = max(maxV - minV, 0.0001)
        let stepX = size.width / CGFloat(values.count - 1)

        var p = Path()
        for (i, v) in values.enumerated() {
            let x = CGFloat(i) * stepX
            let y = size.height - ((v - minV) / range) * size.height
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else      { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }

    private func fillPath(in size: CGSize) -> Path {
        var p = linePath(in: size)
        guard !p.isEmpty else { return p }
        p.addLine(to: CGPoint(x: size.width, y: size.height))
        p.addLine(to: CGPoint(x: 0, y: size.height))
        p.closeSubpath()
        return p
    }
}


#Preview {
    SLCard {
        VStack(alignment: .leading, spacing: 8) {
            SLLabel("● Alle Systeme nominal", color: Theme.accentGreen)
            SLSparkline(values: [12, 18, 16, 22, 20, 28, 24, 32, 26, 30, 22, 34, 28, 36, 30],
                        color: Theme.accentGreen)
                .frame(height: 50)
        }
    }
    .padding()
    .background(Color(red: 0.85, green: 0.93, blue: 1.0))
}
