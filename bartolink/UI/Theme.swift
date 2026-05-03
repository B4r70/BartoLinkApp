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
    
    
    // MARK: - Source-Farben (für Notification-Icons)
    
    /// Mappt eine Source (z.B. "dbticker") auf eine Akzentfarbe + Symbol.
    static func style(for source: String) -> SourceStyle {
        switch source.lowercased() {
        case "dbticker", "transit":
            return SourceStyle(
                color: .blue,
                symbol: "tram.fill"
            )
        case "mailcontrol":
            return SourceStyle(
                color: .indigo,
                symbol: "envelope.fill"
            )
        case "system", "barto-link", "manual-test", "external-test", "krönungstest":
            return SourceStyle(
                color: .purple,
                symbol: "server.rack"
            )
        case "smarthome", "home":
            return SourceStyle(
                color: .green,
                symbol: "house.fill"
            )
        default:
            return SourceStyle(
                color: .gray,
                symbol: "bell.fill"
            )
        }
    }
}


// MARK: - Helpers

struct SourceStyle {
    let color: Color
    let symbol: String  // SF Symbol Name
}
