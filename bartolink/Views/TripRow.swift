//
//  TripRow.swift
//  bartolink
//
//  Created by Barto on 04.05.26.
//


//
//  TripRow.swift
//  bartolink
//
//  Sprint 3b — eine Zeile in der Trip-Inbox.
//  Zeigt einen ganzen Trip mit aktuellem Stand + Anzahl Updates.
//

import SwiftUI


struct TripRow: View {

    let trip: TripGroup
    let isLast: Bool


    // MARK: - Body

    var body: some View {
        let style = Theme.style(for: "dbticker", delayed: trip.isDelayed)

        HStack(alignment: .top, spacing: 12) {
            iconBox(color: style.color, symbol: style.symbol)

            VStack(alignment: .leading, spacing: 2) {
                topLine(accent: style.color)

                Text(headline)
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(-0.08)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 2)

                bottomLine
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
                    .padding(.leading, 14)
            }
        }
        .contentShape(Rectangle())
    }


    // MARK: - Subviews

    private func iconBox(color: Color, symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.tinted(0.16))
            }
    }

    private func topLine(accent: Color) -> some View {
        HStack(spacing: 8) {
            Text(routeLabel)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.ink2)
                .lineLimit(1)
            Spacer(minLength: 8)

            if let chip = statusChip {
                SLChip(text: chip.text, color: chip.color, dot: false)
            }

            if trip.hasUnread {
                Circle()
                    .fill(Theme.accentAmber)
                    .frame(width: 7, height: 7)
            }
        }
    }

    private var bottomLine: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(secondaryText)
                .font(.system(size: 13.5))
                .foregroundStyle(Theme.ink2)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Text(timeText(trip.lastUpdate))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.ink3)
        }
    }


    // MARK: - Texte

    /// Eyebrow: Linie + Richtung kompakt.
    private var routeLabel: String {
        var parts: [String] = []
        if let line = trip.line { parts.append(line) }
        if let direction = trip.direction { parts.append("→ \(direction)") }
        return parts.joined(separator: " ")
            .lowercased()    // Konsistenz mit "dbticker.transit"-Stil aus alter Inbox
    }

    /// Hauptzeile: Status + Verspätung in Klartext.
    private var headline: String {
        if trip.isCancelled {
            return "Zug fällt aus"
        }
        if let delay = trip.currentDelayMinutes, delay > 0 {
            return "Verspätung: +\(delay) Min"
        }
        if trip.currentStatus?.lowercased() == "on_time" {
            return "Pünktlich"
        }
        return trip.line.map { "\($0)" } ?? "Update"
    }

    /// Sekundärzeile: planmäßige Abfahrt + Gleis + Anzahl Updates.
    private var secondaryText: String {
        var parts: [String] = []

        if let dep = trip.plannedDeparture {
            parts.append("ab \(formatTime(dep))")
        }
        if let platform = trip.currentPlatform {
            parts.append("Gleis \(platform)")
        }

        let eventCount = trip.events.count
        if eventCount > 1 {
            parts.append("\(eventCount) Updates")
        }

        return parts.joined(separator: " · ")
    }

    private var statusChip: (text: String, color: Color)? {
        if trip.isCancelled {
            return ("Ausfall", Theme.accentRed)
        }
        if let delay = trip.currentDelayMinutes, delay > 0 {
            return ("+\(delay) Min", Theme.accentAmber)
        }
        if trip.currentStatus?.lowercased() == "on_time" {
            return ("Pünktlich", Theme.accentGreen)
        }
        return nil
    }


    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Europe/Berlin")
        return f.string(from: date)
    }

    private func timeText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}