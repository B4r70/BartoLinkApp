//
//  TripListView.swift
//  bartolink
//
//  Created by Barto on 04.05.26.
//


//
//  TripListView.swift
//  bartolink
//
//  Sprint 3b — neue Inbox mit Trip-Gruppierung.
//
//  Ersetzt NotificationListView. Gruppiert StoredNotifications nach tripKey,
//  zeigt eine Zeile pro Trip, Tagessektionen für ältere Trips.
//
//  Notifications ohne tripKey (z.B. mailcontrol) erscheinen am Ende als
//  "Sonstige" — nicht gruppiert, aber sichtbar.
//

import SwiftUI
import SwiftData


struct TripListView: View {

    @Query(sort: \StoredNotification.receivedAt, order: .reverse)
    private var notifications: [StoredNotification]

    @Environment(\.modelContext) private var modelContext

    @State private var detailTarget: TripGroup?


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

                        Color.clear.frame(height: 110)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $detailTarget) { trip in
                TripDetailView(trip: trip)
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
        let (groups, loose) = TripGroup.group(notifications)
        let sections = groupByDay(groups)

        VStack(alignment: .leading, spacing: 18) {
            ForEach(sections, id: \.title) { section in
                tripSection(title: section.title, trips: section.trips)
            }

            if !loose.isEmpty {
                looseSection(notifications: loose)
            }
        }
    }


    // MARK: - Section pro Tag

    private func tripSection(title: String, trips: [TripGroup]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SLLabel(title, color: Theme.ink2)

            VStack(spacing: 0) {
                ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                    TripRow(trip: trip, isLast: index == trips.count - 1)
                        .onTapGesture {
                            markAsRead(trip)
                            detailTarget = trip
                        }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.cardFill)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Theme.cardShadow, radius: 18, x: 0, y: 6)
        }
    }


    // MARK: - "Sonstige"-Sektion (Notifications ohne tripKey)

    private func looseSection(notifications: [StoredNotification]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SLLabel("Sonstige", color: Theme.ink2)

            VStack(spacing: 0) {
                ForEach(Array(notifications.enumerated()), id: \.element.id) { index, n in
                    LooseNotificationRow(notification: n, isLast: index == notifications.count - 1)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.cardFill)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Theme.cardShadow, radius: 18, x: 0, y: 6)
        }
    }


    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.ink3)
            Text("Noch keine Notifications")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink2)
            Text("Trips erscheinen hier, sobald dbticker etwas meldet.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }


    // MARK: - Tagessektionen

    private struct DaySection {
        let title: String
        let trips: [TripGroup]
    }

    private func groupByDay(_ trips: [TripGroup]) -> [DaySection] {
        let cal = Calendar.current
        let now = Date()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")

        var byTitle: [String: [TripGroup]] = [:]
        var titleOrder: [String] = []

        for trip in trips {
            let ref = trip.plannedDeparture ?? trip.lastUpdate
            let title: String

            if cal.isDateInToday(ref) {
                title = "Heute"
            } else if cal.isDateInYesterday(ref) {
                title = "Gestern"
            } else if let days = cal.dateComponents([.day], from: ref, to: now).day,
                      days < 7 {
                formatter.dateFormat = "EEEE"
                title = formatter.string(from: ref).capitalized
            } else {
                formatter.dateFormat = "EEE · dd.MM."
                title = formatter.string(from: ref).capitalized
            }

            if byTitle[title] == nil {
                titleOrder.append(title)
            }
            byTitle[title, default: []].append(trip)
        }

        return titleOrder.map { DaySection(title: $0, trips: byTitle[$0] ?? []) }
    }


    // MARK: - Aktionen

    private func markAsRead(_ trip: TripGroup) {
        for event in trip.events where !event.isRead {
            event.isRead = true
        }
        try? modelContext.save()
    }

    private func deleteAll() {
        for item in notifications {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}


// MARK: - Loose Row (für nicht-Trip-Notifications)

private struct LooseNotificationRow: View {
    let notification: StoredNotification
    let isLast: Bool

    var body: some View {
        let style = Theme.style(
            for: notification.source,
            delayed: notification.isDelayed
        )

        HStack(alignment: .top, spacing: 12) {
            Image(systemName: style.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(style.color)
                .frame(width: 36, height: 36)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(style.color.tinted(0.16))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(notification.source.lowercased())
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.ink2)
                    .lineLimit(1)

                Text(notification.title)
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(-0.08)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .padding(.top, 2)

                Text(notification.body)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.ink2)
                    .lineLimit(2)
                    .padding(.top, 2)
            }

            Spacer(minLength: 8)

            Text(formatTime(notification.receivedAt))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.ink3)
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
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}