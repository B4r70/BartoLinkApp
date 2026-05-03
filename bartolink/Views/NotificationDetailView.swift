//
//  NotificationDetailView.swift
//  bartolink
//
//  Created by Barto on 03.05.26.
//


//
//  NotificationDetailView.swift
//  bartolink
//
//  Detail-Ansicht einer einzelnen Notification mit allen Metadaten.
//

import SwiftUI


struct NotificationDetailView: View {
    
    let notification: StoredNotification
    
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                if notification.hasTrainMetadata {
                    Divider()
                    trainSection
                    
                    if let reason = notification.delayReason, !reason.isEmpty {
                        Divider()
                        reasonSection(reason: reason)
                    }
                    
                    Divider()
                    routeSection
                }
                
                Divider()
                rawBodySection
                Divider()
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(notification.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(notification.receivedAt, style: .date) +
            Text(" · ") +
            Text(notification.receivedAt, style: .time)
        }
        .foregroundStyle(.primary)
    }
    
    private var trainSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Zug")
            
            if let line = notification.trainLine {
                detailRow(label: "Linie", value: trainLineLabel(line: line))
            }
            if let dest = notification.destination {
                detailRow(label: "Richtung", value: dest)
            }
            if let platform = notification.plannedPlatform {
                detailRow(label: "Gleis", value: platform)
            }
            
            if let planned = notification.plannedDeparture {
                let plannedStr = formatTime(planned)
                if let actual = notification.actualDeparture, actual != planned {
                    detailRow(
                        label: "Abfahrt",
                        value: "\(plannedStr) → \(formatTime(actual))",
                        valueColor: .red
                    )
                } else {
                    detailRow(label: "Abfahrt", value: plannedStr)
                }
            }
            
            if let delay = notification.delayMinutes, delay > 0 {
                detailRow(
                    label: "Verspätung",
                    value: "+\(delay) Min",
                    valueColor: .red
                )
            }
        }
    }
    
    private func reasonSection(reason: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Grund")
            HStack(spacing: 8) {
                severityIndicator(for: notification.delayReasonSeverity)
                Text(reason)
                    .font(.body)
            }
        }
    }
    
    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Strecke")
            if let from = notification.fromStation {
                detailRow(label: "Einsteigen", value: from)
            }
            if let to = notification.toStation {
                detailRow(label: "Aussteigen", value: to)
            }
        }
    }
    
    private var rawBodySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Nachricht")
            Text(notification.body)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quelle: \(notification.source)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    
    // MARK: - Reusable Components
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
    
    private func detailRow(
        label: String,
        value: String,
        valueColor: Color = .primary
    ) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.body)
                .foregroundStyle(valueColor)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func severityIndicator(for severity: String?) -> some View {
        let color: Color = switch severity {
            case "critical": .red
            case "high":     .orange
            case "medium":   .yellow
            case "low":      .green
            default:         .gray
        }
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
    
    
    // MARK: - Formatting
    
    private func trainLineLabel(line: String) -> String {
        if let number = notification.trainNumber {
            return "\(line) (\(number))"
        }
        return line
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        return formatter.string(from: date)
    }
}


// MARK: - Preview

#Preview("Mit Verspätung") {
    NavigationStack {
        NotificationDetailView(notification: .preview_delayed)
    }
}

#Preview("Pünktlich") {
    NavigationStack {
        NotificationDetailView(notification: .preview_onTime)
    }
}


// MARK: - Preview Mocks

extension StoredNotification {
    
    static var preview_delayed: StoredNotification {
        StoredNotification(
            title: "🔴 RB23 verspätet: +7 Min",
            body: "Abfahrt: 06:31 → 06:38 (Bad Ems, Gleis 1)\nAussteigen: Niederlahnstein\nGrund: Weichen\n\nDu kannst 7 Min später losfahren.",
            source: "dbticker.transit",
            trainLine: "RB23",
            trainNumber: "12614",
            destination: "Andernach",
            plannedDeparture: Calendar.current.date(bySettingHour: 6, minute: 31, second: 0, of: .now),
            actualDeparture: Calendar.current.date(bySettingHour: 6, minute: 38, second: 0, of: .now),
            delayMinutes: 7,
            plannedPlatform: "1",
            delayReason: "Weichen",
            delayReasonSeverity: "high",
            fromStation: "Bad Ems",
            toStation: "Niederlahnstein",
            statusRaw: "delayed"
        )
    }
    
    static var preview_onTime: StoredNotification {
        StoredNotification(
            title: "🟢 RB23 pünktlich",
            body: "Abfahrt: 06:31 (Bad Ems, Gleis 1)\nAussteigen: Niederlahnstein",
            source: "dbticker.transit",
            trainLine: "RB23",
            trainNumber: "12614",
            destination: "Koblenz Hbf",
            plannedDeparture: Calendar.current.date(bySettingHour: 6, minute: 31, second: 0, of: .now),
            delayMinutes: 0,
            plannedPlatform: "1",
            fromStation: "Bad Ems",
            toStation: "Niederlahnstein",
            statusRaw: "on_time"
        )
    }
}