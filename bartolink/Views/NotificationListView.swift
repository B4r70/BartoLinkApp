//
//  NotificationListView.swift
//  bartolink
//
//  Inbox-Tab. Header + optionaler Live-Hero + Tagessektionen.
//

import SwiftUI
import SwiftData


struct NotificationListView: View {

    @Query(sort: \StoredNotification.receivedAt, order: .reverse)
    private var notifications: [StoredNotification]

    @Environment(\.modelContext) private var modelContext

    @State private var detailTarget: StoredNotification?


    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        if notifications.isEmpty {
                            emptyState
                                .padding(.top, 60)
                        } else {
                            content
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                        }

                        Color.clear.frame(height: 110)   // Platz für Tab-Bar-Overlay
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $detailTarget) { item in
                NotificationDetailView(notification: item)
            }
        }
    }


    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                SLLabel(headerEyebrow, color: Theme.ink2)
                Text("Inbox")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.7)
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            HStack(spacing: 8) {
                SLIconButton(systemName: "magnifyingglass")
                Menu {
                    if !notifications.isEmpty {
                        Button(role: .destructive) {
                            deleteAll()
                        } label: {
                            Label("Alle löschen", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink2)
                        .frame(width: 36, height: 36)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .overlay {
                            Circle().strokeBorder(Theme.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private var headerEyebrow: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE · dd MMM"
        return f.string(from: Date())
    }


    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        let groups = groupByDay(notifications)
        let hero = notifications.first { $0.liveHeroEligible }

        VStack(alignment: .leading, spacing: 18) {
            if let hero {
                LiveHeroCard(notification: hero)
                    .onTapGesture { detailTarget = hero }
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            ForEach(groups, id: \.title) { section in
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader(title: section.title, count: section.items.count)
                        .padding(.horizontal, 4)

                    SLCard(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(section.items.enumerated()), id: \.element.id) { idx, item in
                                Button {
                                    detailTarget = item
                                } label: {
                                    NotificationRow(
                                        notification: item,
                                        isLast: idx == section.items.count - 1
                                    )
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(item)
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hero?.id)
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .tracking(-0.17)
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(count) \(count == 1 ? "Signal" : "Signale")")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.ink3)
        }
    }


    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(Theme.ink3)
            Text("Keine Notifications")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Sobald ein Tool einen Push schickt,\nlandet er hier.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink2)
                .font(.system(size: 14))
        }
        .frame(maxWidth: .infinity)
        .padding()
    }


    // MARK: - Grouping

    private struct DaySection {
        let title: String
        let items: [StoredNotification]
    }

    private func groupByDay(_ items: [StoredNotification]) -> [DaySection] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: items) { item -> Date in
            calendar.startOfDay(for: item.receivedAt)
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, items) in
                DaySection(title: formatDate(date), items: items)
            }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Heute" }
        if calendar.isDateInYesterday(date) { return "Gestern" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: date).capitalized
    }


    // MARK: - Delete

    private func delete(_ item: StoredNotification) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    private func deleteAll() {
        for item in notifications {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}


// MARK: - Row

private struct NotificationRow: View {

    let notification: StoredNotification
    let isLast: Bool

    var body: some View {
        let style = Theme.style(
            for: notification.source,
            delayed: notification.isDelayed
        )

        HStack(alignment: .top, spacing: 12) {
            iconBox(color: style.color, symbol: style.symbol)

            VStack(alignment: .leading, spacing: 2) {
                topLine(accent: style.color)

                Text(notification.title)
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
            Text(notification.source.lowercased())
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.ink2)
                .lineLimit(1)
            Spacer(minLength: 8)

            if let chip = statusChip {
                SLChip(text: chip.text, color: chip.color, dot: false)
            }

            if !notification.isRead {
                Circle()
                    .fill(Theme.accentAmber)
                    .frame(width: 7, height: 7)
            }
        }
    }

    private var bottomLine: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(notification.body)
                .font(.system(size: 13.5))
                .foregroundStyle(Theme.ink2)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Text(timeText(notification.receivedAt))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.ink3)
        }
    }

    private var statusChip: (text: String, color: Color)? {
        if let delay = notification.delayMinutes, delay > 0 {
            return ("+\(delay) Min", Theme.accentAmber)
        }
        switch notification.statusRaw?.lowercased() {
        case "on_time", "ontime", "punctual":
            return ("Pünktlich", Theme.accentGreen)
        case "delayed":
            return ("Verspätet", Theme.accentAmber)
        case "ok":
            return ("OK", Theme.accentGreen)
        default:
            break
        }
        // Fallback: kurzer Source-Hinweis als neutraler Chip
        let normalized = notification.source.lowercased()
        if normalized.contains("mailcontrol") {
            return ("Neu", Theme.accentViolet)
        }
        return nil
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}


// MARK: - Live Hero

private struct LiveHeroCard: View {

    let notification: StoredNotification

    var body: some View {
        let accent = notification.isDelayed ? Theme.accentAmber : Theme.accentGreen

        SLCard(padding: 0, topTint: accent) {
            VStack(alignment: .leading, spacing: 0) {
                topRow(accent: accent)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                timeRow
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                lineRow
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                progress(accent: accent)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                routeRow
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 14)
            }
        }
    }

    private func topRow(accent: Color) -> some View {
        HStack {
            SLChip(text: chipText, color: accent)
            Spacer()
            Text(relativeTimeText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.ink3)
        }
    }

    @ViewBuilder
    private var timeRow: some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            Text(formatTime(displayDeparture))
                .font(.system(size: 48, weight: .bold))
                .tracking(-1.4)
                .foregroundStyle(Theme.ink)

            if showsStrikePlanned, let planned = notification.plannedDeparture {
                Text(formatTime(planned))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.ink3)
                    .strikethrough(true, color: Theme.ink3)
            }
        }
    }

    private var lineRow: some View {
        HStack(spacing: 10) {
            if let line = notification.trainLine {
                Text(line)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.accentBlue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Theme.accentBlue.tinted(0.14))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Theme.accentBlue.opacity(0.3), lineWidth: 1)
                    }
            }
            Text(routeDescription)
                .font(.system(size: 14))
                .foregroundStyle(Theme.ink2)
                .lineLimit(1)
            Spacer()
        }
    }

    private func progress(accent: Color) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress: CGFloat = 0.32
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.hairline)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.4)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: width * progress)
            }
        }
        .frame(height: 5)
    }

    private var routeRow: some View {
        HStack {
            Text(notification.fromStation ?? "Start")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.ink3)
            Spacer()
            Text(notification.toStation ?? "Ziel")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.ink3)
        }
    }


    // MARK: - Helpers

    private var displayDeparture: Date {
        notification.actualDeparture
            ?? notification.plannedDeparture
            ?? notification.receivedAt
    }

    private var showsStrikePlanned: Bool {
        guard
            let actual = notification.actualDeparture,
            let planned = notification.plannedDeparture
        else { return false }
        return abs(actual.timeIntervalSince(planned)) > 30
    }

    private var chipText: String {
        if let delay = notification.delayMinutes, delay > 0 {
            return "Verspätet · +\(delay) Min"
        }
        if notification.isDelayed {
            return "Verspätet"
        }
        return "Pünktlich"
    }

    private var relativeTimeText: String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.unitsStyle = .short
        return f.localizedString(for: notification.receivedAt, relativeTo: Date())
    }

    private var routeDescription: String {
        var parts: [String] = []
        if let dest = notification.destination {
            parts.append("nach \(dest)")
        } else if let to = notification.toStation {
            parts.append("nach \(to)")
        }
        if let platform = notification.plannedPlatform {
            parts.append("Gleis \(platform)")
        }
        return parts.isEmpty ? notification.body : parts.joined(separator: " · ")
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Europe/Berlin")
        return f.string(from: date)
    }
}


// MARK: - Preview

#Preview {
    NotificationListView()
        .modelContainer(for: StoredNotification.self, inMemory: true)
}
