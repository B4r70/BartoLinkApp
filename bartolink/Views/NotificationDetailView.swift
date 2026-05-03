//
//  NotificationDetailView.swift
//  bartolink
//
//  Detail-Ansicht einer einzelnen Notification mit allen Metadaten.
//

import SwiftUI


struct NotificationDetailView: View {

    let notification: StoredNotification

    @Environment(\.dismiss) private var dismiss


    // MARK: - Body

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headlineBlock

                    if notification.hasTrainMetadata {
                        timeCard
                    }

                    if let reason = notification.delayReason, !reason.isEmpty {
                        reasonCard(reason: reason)
                    }

                    if notification.fromStation != nil || notification.toStation != nil {
                        routeCard
                    }

                    messageCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 110)   // Platz für Tab-Bar-Overlay
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
    }


    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Inbox")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(Theme.accentBlue)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            SLIconButton(systemName: "ellipsis")
        }
    }


    // MARK: - Headline

    private var headlineBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let chip = severityChip {
                SLChip(text: chip.text, color: chip.color)
            }
            Text(headlineText)
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.66)
                .foregroundStyle(Theme.ink)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(headlineSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink3)
        }
        .padding(.top, 4)
    }

    private var headlineText: String {
        if let line = notification.trainLine, let dest = notification.destination {
            return "\(line) nach\n\(dest)"
        }
        return notification.title
    }

    private var headlineSubtitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "dd.MM.yyyy, HH:mm"
        let when = f.string(from: notification.receivedAt)
        return "\(when) · \(notification.source.lowercased())"
    }

    private var severityChip: (text: String, color: Color)? {
        if let delay = notification.delayMinutes, delay > 0 {
            let level = Theme.severityLabel(notification.delayReasonSeverity)
            let suffix = level == "—" ? "" : " · \(level)"
            return ("Verspätung\(suffix)", Theme.severityColor(notification.delayReasonSeverity == nil ? "high" : notification.delayReasonSeverity))
        }
        if notification.isDelayed {
            return ("Verspätung", Theme.accentAmber)
        }
        if notification.statusRaw?.lowercased() == "on_time" {
            return ("Pünktlich", Theme.accentGreen)
        }
        return nil
    }


    // MARK: - Time Card

    private var timeCard: some View {
        let accent: Color = notification.isDelayed ? Theme.accentAmber : Theme.accentGreen

        return SLCard(padding: 0, accent: accent) {
            VStack(spacing: 0) {
                // Top: Geplant → Neu
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        SLLabel("Geplant")
                        Text(plannedTimeText)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Theme.ink3)
                            .strikethrough(showsStrike, color: Theme.ink3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.ink3)
                        .padding(.top, 22)

                    VStack(alignment: .leading, spacing: 4) {
                        SLLabel("Neu", color: accent)
                        Text(newTimeText)
                            .font(.system(size: 38, weight: .bold))
                            .tracking(-0.95)
                            .foregroundStyle(Theme.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)

                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)

                // Bottom: KPI-Grid
                HStack(spacing: 0) {
                    SLKPI(
                        label: "Linie",
                        value: notification.trainLine ?? "—",
                        sub: notification.trainNumber.map { "Nr. \($0)" }
                    )
                    SLKPI(
                        label: "Gleis",
                        value: notification.plannedPlatform ?? "—",
                        sub: notification.fromStation,
                        divider: true
                    )
                    SLKPI(
                        label: "Verspätung",
                        value: delayValue,
                        sub: "Minuten",
                        valueColor: notification.isDelayed ? Theme.accentAmber : Theme.ink,
                        divider: true
                    )
                }
            }
        }
    }

    private var plannedTimeText: String {
        guard let p = notification.plannedDeparture else { return "—" }
        return formatTime(p)
    }

    private var newTimeText: String {
        let d = notification.actualDeparture
            ?? notification.plannedDeparture
            ?? notification.receivedAt
        return formatTime(d)
    }

    private var showsStrike: Bool {
        guard
            let a = notification.actualDeparture,
            let p = notification.plannedDeparture
        else { return false }
        return abs(a.timeIntervalSince(p)) > 30
    }

    private var delayValue: String {
        if let d = notification.delayMinutes, d > 0 { return "+\(d)" }
        return "0"
    }


    // MARK: - Reason Card

    private func reasonCard(reason: String) -> some View {
        let severityColor = Theme.severityColor(notification.delayReasonSeverity)
        let severityLabel = Theme.severityLabel(notification.delayReasonSeverity)

        return SLCard(accent: severityColor) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SLLabel("Grund")
                    Spacer()
                    if severityLabel != "—" {
                        SLChip(text: "Severity · \(severityLabel)", color: severityColor, dot: false)
                    }
                }
                Text(reason)
                    .font(.system(size: 20, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(Theme.ink)

                if let hint = explanationHint {
                    Text(hint)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.ink2)
                        .lineSpacing(2)
                }
            }
        }
    }

    private var explanationHint: String? {
        guard let delay = notification.delayMinutes, delay > 0 else { return nil }
        if let to = notification.toStation {
            return "Du kannst \(delay) Minuten später losfahren — Anschluss in \(to) laut DB-System weiterhin erreichbar."
        }
        return "Du kannst \(delay) Minuten später losfahren."
    }


    // MARK: - Route Card

    private var routeCard: some View {
        SLCard {
            VStack(alignment: .leading, spacing: 14) {
                SLLabel("Strecke")
                routeTimeline
            }
        }
    }

    private var routeTimeline: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Theme.accentBlue)
                    .frame(width: 11, height: 11)
                    .overlay {
                        Circle()
                            .strokeBorder(Theme.accentBlue.opacity(0.18), lineWidth: 3)
                            .scaleEffect(1.7)
                    }
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 4)
                Circle()
                    .strokeBorder(Theme.accentBlue, lineWidth: 2.5)
                    .background(Circle().fill(Color.white))
                    .frame(width: 11, height: 11)
            }
            .padding(.top, 4)
            .frame(width: 16)

            VStack(alignment: .leading, spacing: 0) {
                if let from = notification.fromStation {
                    Text(from)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(boardingText)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.ink3)
                        .padding(.top, 2)
                }

                Spacer().frame(height: 22)

                if let to = notification.toStation {
                    Text(to)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Aussteigen")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.ink3)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var boardingText: String {
        var parts: [String] = ["Einsteigen"]
        let dep = notification.actualDeparture ?? notification.plannedDeparture
        if let dep { parts.append(formatTime(dep)) }
        if let platform = notification.plannedPlatform {
            parts.append("Gleis \(platform)")
        }
        return parts.joined(separator: " · ")
    }


    // MARK: - Message

    private var messageCard: some View {
        SLCard {
            VStack(alignment: .leading, spacing: 10) {
                SLLabel("Nachricht")
                Text(notification.body)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink2)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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
            body: """
            Abfahrt 06:31 → 06:38 (Bad Ems, Gleis 1)
            Aussteigen: Niederlahnstein
            Grund: Weichen
            """,
            source: "dbticker.transit",
            trainLine: "RB23",
            trainNumber: "12614",
            destination: "Andernach",
            plannedDeparture: Calendar.current.date(bySettingHour: 6, minute: 31, second: 0, of: .now),
            actualDeparture: Calendar.current.date(bySettingHour: 6, minute: 38, second: 0, of: .now),
            delayMinutes: 7,
            plannedPlatform: "1",
            delayReason: "Weichenstörung",
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
