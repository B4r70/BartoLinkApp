//
//  TripEventRow.swift
//  bartolink
//
//  Created by Barto on 04.05.26.
//


//
//  TripEventRow.swift
//  bartolink
//
//  Sprint 3b — eine Zeile in der Event-History eines Trips.
//  Zeigt Zeitpunkt + Event-Typ + relevante Daten (Verspätung, Gleis, etc.).
//

import SwiftUI


struct TripEventRow: View {

    let event: StoredNotification
    let isFirst: Bool
    let isLast: Bool


    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            timelineDot

            VStack(alignment: .leading, spacing: 4) {
                topLine
                contentLine
            }
            .padding(.bottom, isLast ? 0 : 14)
        }
    }


    // MARK: - Timeline-Punkt mit Verbindungslinie

    private var timelineDot: some View {
        VStack(spacing: 0) {
            if !isFirst {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 2, height: 8)
            } else {
                Color.clear.frame(width: 2, height: 8)
            }

            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)
                .overlay {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                }

            if !isLast {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 10)
    }


    // MARK: - Inhalt

    private var topLine: some View {
        HStack(spacing: 8) {
            Text(formatTime(event.receivedAt))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.ink2)

            Text(eventTypeLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.ink3)
                .textCase(.uppercase)
                .tracking(0.3)

            Spacer()

            if event.eventType == "manual_refresh" {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.ink3)
            }
        }
    }

    private var contentLine: some View {
        Text(contentText)
            .font(.system(size: 14))
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(.leading)
    }


    // MARK: - Texte

    private var eventTypeLabel: String {
        switch event.eventType {
        case "delay":            return "Verspätung"
        case "platform_change":  return "Gleisänderung"
        case "cancelled":        return "Ausfall"
        case "on_time":          return "Pünktlich"
        case "not_found":        return "Nicht im Plan"
        case "manual_refresh":   return "Refresh"
        default:                 return "Update"
        }
    }

    private var contentText: String {
        var parts: [String] = []

        if let delay = event.delayMinutes, delay > 0 {
            parts.append("+\(delay) Min")
        }

        if let platform = event.currentPlatform {
            parts.append("Gleis \(platform)")
        }

        if let reason = event.delayReason, !reason.isEmpty {
            parts.append(reason)
        }

        if parts.isEmpty {
            return event.body
        }
        return parts.joined(separator: " · ")
    }

    private var dotColor: Color {
        switch event.eventType {
        case "cancelled":        return Theme.accentRed
        case "platform_change":  return Theme.accentViolet
        case "on_time":          return Theme.accentGreen
        case "delay":
            if let d = event.delayMinutes, d > 0 {
                return Theme.accentAmber
            }
            return Theme.accentBlue
        case "manual_refresh":   return Theme.ink3
        default:                 return Theme.accentBlue
        }
    }


    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Europe/Berlin")
        return f.string(from: date)
    }
}