//
//  Theme.swift
//  bartolink
//
//  Zentrale Farb- und Style-Definitionen.
//  Änderungen hier = überall.
//

import SwiftUI


enum Theme {

    // MARK: - Background Gradient

    /// Pastel-blauer Hintergrund — von oben hell zu mittel.
    /// Nutzt @Environment(\.colorScheme) für Dark Mode-Anpassung.
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.10, blue: 0.18),
                    Color(red: 0.02, green: 0.04, blue: 0.10),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.93, blue: 1.00),  // sehr hell oben
                    Color(red: 0.72, green: 0.85, blue: 0.98),  // etwas tiefer unten
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }


    // MARK: - Ink (Vordergrund-Stufen)

    static let ink   = Color(red: 0.059, green: 0.122, blue: 0.200)   // 0x0F1F33
    static let ink2  = Color(red: 0.290, green: 0.353, blue: 0.447)   // 0x4A5A72
    static let ink3  = Color(red: 0.522, green: 0.576, blue: 0.659)   // 0x8593A8


    // MARK: - Card / Surface

    static let cardFill   = Color.white.opacity(0.78)
    static let cardStroke = Color(red: 0.06, green: 0.13, blue: 0.24).opacity(0.08)
    static let hairline   = Color(red: 0.06, green: 0.13, blue: 0.24).opacity(0.10)
    static let cardShadow = Color(red: 0.06, green: 0.13, blue: 0.24).opacity(0.06)


    // MARK: - Akzentfarben

    static let accentBlue   = Color(red: 0.165, green: 0.490, blue: 0.851)   // 0x2A7DD9
    static let accentAmber  = Color(red: 0.878, green: 0.545, blue: 0.173)   // 0xE08B2C
    static let accentAmberLight = Color(red: 0.937, green: 0.706, blue: 0.353) // medium severity
    static let accentGreen  = Color(red: 0.169, green: 0.655, blue: 0.420)   // 0x2BA76B
    static let accentViolet = Color(red: 0.545, green: 0.435, blue: 0.878)   // 0x8B6FE0
    static let accentRed    = Color(red: 0.855, green: 0.290, blue: 0.227)   // 0xDA4A3A


    // MARK: - Source-Farben (für Notification-Icons)

    /// Mappt eine Source (z.B. "dbticker") auf eine Akzentfarbe + Symbol.
    /// Wenn `delayed` true ist, wird für transit-Sources amber statt blue
    /// zurückgegeben (Live-Hero-Highlight).
    static func style(for source: String, delayed: Bool = false) -> SourceStyle {
        let normalized = source.lowercased()

        // dbticker / transit — blue oder amber bei Verspätung
        if normalized.contains("dbticker") || normalized.contains("transit") {
            return SourceStyle(
                color: delayed ? accentAmber : accentBlue,
                symbol: "tram.fill"
            )
        }

        if normalized.contains("mailcontrol") {
            return SourceStyle(color: accentViolet, symbol: "envelope.fill")
        }

        if normalized == "system"
            || normalized.contains("barto-link")
            || normalized.contains("manual-test")
            || normalized.contains("external-test")
            || normalized.contains("krönungstest")
        {
            return SourceStyle(color: accentViolet, symbol: "server.rack")
        }

        if normalized.contains("smarthome") || normalized.contains("home") {
            return SourceStyle(color: accentGreen, symbol: "house.fill")
        }

        return SourceStyle(color: ink3, symbol: "bell.fill")
    }


    // MARK: - Severity Mapping

    /// `delayReasonSeverity` → Akzentfarbe.
    static func severityColor(_ severity: String?) -> Color {
        switch severity?.lowercased() {
        case "critical": return accentRed
        case "high":     return accentAmber
        case "medium":   return accentAmberLight
        case "low":      return accentGreen
        default:         return ink3
        }
    }

    /// Lesbare Beschriftung für die Severity-Stufe.
    static func severityLabel(_ severity: String?) -> String {
        switch severity?.lowercased() {
        case "critical": return "Kritisch"
        case "high":     return "Hoch"
        case "medium":   return "Mittel"
        case "low":      return "Niedrig"
        default:         return "—"
        }
    }
}


// MARK: - Helpers

struct SourceStyle {
    let color: Color
    let symbol: String  // SF Symbol Name
}


// MARK: - Color Convenience

extension Color {
    /// Mischt zwei Farben gewichtet — Ersatz für CSS `color-mix(in oklch, ...)`.
    /// `t` = 0 → self, 1 → other.
    func mix(with other: Color, by t: CGFloat) -> Color {
        let a = UIColor(self)
        let b = UIColor(other)
        var (r1, g1, bl1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, bl2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        a.getRed(&r1, green: &g1, blue: &bl1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &bl2, alpha: &a2)
        let f = max(0, min(1, t))
        return Color(
            red:   Double(r1 + (r2 - r1) * f),
            green: Double(g1 + (g2 - g1) * f),
            blue:  Double(bl1 + (bl2 - bl1) * f),
            opacity: Double(a1 + (a2 - a1) * f)
        )
    }

    /// Helle, sanfte Tönung der Farbe auf weißem Grund (für Chip-/Icon-Backgrounds).
    func tinted(_ amount: CGFloat = 0.16) -> Color {
        Color.white.mix(with: self, by: amount)
    }
}
