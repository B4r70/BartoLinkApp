//
//  TripDetailView.swift
//  bartolink
//
//  Created by Barto on 04.05.26.
//


//
//  TripDetailView.swift
//  bartolink
//
//  Sprint 3b — Detail-Ansicht eines aggregierten Trips.
//
//  Zeigt:
//    - Trip-Stammdaten (Linie, Richtung, geplante Abfahrt)
//    - Aktueller Stand (Verspätung, Gleis, Status)
//    - Refresh-Button (mit Cooldown)
//    - Event-History chronologisch
//

import SwiftUI


struct TripDetailView: View {

    let trip: TripGroup

    @StateObject private var refreshController = TripRefreshController()
    @Environment(\.dismiss) private var dismiss


    // MARK: - Body

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headlineBlock
                    statusCard
                    refreshSection
                    historyCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 110)
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
    }


    // MARK: - Headline

    private var headlineBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let chip = severityChip {
                SLChip(text: chip.text, color: chip.color)
            }

            Text(headlineText)
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)

            if let dateLine = dateLineText {
                Text(dateLine)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.ink2)
            }
        }
    }


    // MARK: - Status-Karte

    private var statusCard: some View {
        SLCard {
            HStack(spacing: 0) {
                SLKPI(
                    label: "Geplant",
                    value: plannedTimeText,
                    sub: trip.plannedPlatform.map { "Gleis \($0)" }
                )
                SLKPI(
                    label: "Aktuell",
                    value: currentTimeText,
                    sub: trip.currentPlatform.map { "Gleis \($0)" },
                    valueColor: trip.isDelayed ? Theme.accentAmber : Theme.ink,
                    divider: true
                )
                SLKPI(
                    label: "Verspätung",
                    value: delayValueText,
                    sub: "Minuten",
                    valueColor: trip.isDelayed ? Theme.accentAmber : Theme.ink,
                    divider: true
                )
            }
        }
    }


    // MARK: - Refresh-Sektion

    private var refreshSection: some View {
        RefreshButton(
            tripKey: trip.tripKey,
            disabled: !trip.isToday,
            disabledHint: trip.isToday ? nil : "Trip in der Vergangenheit",
            controller: refreshController
        )
    }


    // MARK: - History

    private var historyCard: some View {
        SLCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SLLabel("Verlauf")
                    Spacer()
                    Text("\(trip.events.count) \(trip.events.count == 1 ? "Eintrag" : "Einträge")")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.ink3)
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(trip.events.enumerated()), id: \.element.id) { index, event in
                        TripEventRow(
                            event: event,
                            isFirst: index == 0,
                            isLast: index == trip.events.count - 1
                        )
                    }
                }
            }
        }
    }


    // MARK: - Texte

    private var headlineText: String {
        var parts: [String] = []
        if let line = trip.line { parts.append(line) }
        if let direction = trip.direction { parts.append("→ \(direction)") }
        return parts.isEmpty ? "Trip" : parts.joined(separator: " ")
    }

    private var dateLineText: String? {
        guard let dep = trip.plannedDeparture else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE, dd.MM.yyyy"
        return f.string(from: dep)
    }

    private var plannedTimeText: String {
        guard let dep = trip.plannedDeparture else { return "—" }
        return formatTime(dep)
    }

    private var currentTimeText: String {
        guard let dep = trip.plannedDeparture else { return "—" }
        guard let delay = trip.currentDelayMinutes, delay > 0 else {
            return formatTime(dep)
        }
        return formatTime(dep.addingTimeInterval(TimeInterval(delay * 60)))
    }

    private var delayValueText: String {
        guard let delay = trip.currentDelayMinutes else { return "0" }
        return delay > 0 ? "+\(delay)" : "0"
    }

    private var severityChip: (text: String, color: Color)? {
        if trip.isCancelled {
            return ("Ausfall", Theme.accentRed)
        }
        if let delay = trip.currentDelayMinutes, delay > 0 {
            return ("Verspätet · +\(delay) Min", Theme.accentAmber)
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
}