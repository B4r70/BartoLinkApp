//
//  TripGroup.swift
//  bartolink
//
//  Sprint 3b — clientseitige Trip-Gruppierung.
//
//  Aggregiert StoredNotification-Objekte mit demselben tripKey zu einem
//  TripGroup-Wert. Dient als Datenquelle für TripListView und TripDetailView.
//
//  Pure Value-Type — kein SwiftData. Wird bei jedem Render aus dem aktuellen
//  Notification-Set neu berechnet (kostengünstig bei < paar Tausend Einträgen).
//

import Foundation


/// Aggregierte Sicht auf alle Notifications eines Trips.
struct TripGroup: Identifiable, Hashable {

    /// Eindeutige ID = tripKey.
    let id: String
    let tripKey: String

    /// Stammdaten aus der NEUESTEN Notification dieses Trips.
    let line: String?
    let trainNumber: String?
    let direction: String?
    let plannedDeparture: Date?
    let plannedPlatform: String?
    let routeId: String?
    let fromStation: String?
    let toStation: String?

    /// Aktuellster Stand (jüngste Notification).
    let currentStatus: String?
    let currentDelayMinutes: Int?
    let currentPlatform: String?

    /// Wann kam die jüngste Notification an? Sortier-Schlüssel der Inbox.
    let lastUpdate: Date

    /// Alle Notifications dieses Trips, chronologisch (älteste zuerst).
    /// In der DetailView die Event-History.
    let events: [StoredNotification]


    // MARK: - Convenience

    var isDelayed: Bool {
        if let d = currentDelayMinutes, d > 0 { return true }
        return currentStatus?.lowercased() == "delayed"
    }

    var isCancelled: Bool {
        currentStatus?.lowercased() == "cancelled"
    }

    var hasUnread: Bool {
        events.contains { !$0.isRead }
    }

    /// Ist dieser Trip "von heute" (= refreshbar)?
    /// Trips in der Vergangenheit oder Zukunft können nicht refresht werden.
    var isToday: Bool {
        let cal = Calendar.current
        if let dep = plannedDeparture {
            return cal.isDateInToday(dep)
        }
        return cal.isDateInToday(lastUpdate)
    }
}


// MARK: - Aggregation

extension TripGroup {

    /// Gruppiert eine flache Liste von StoredNotifications nach tripKey.
    ///
    /// Notifications OHNE tripKey (Pre-Sprint-3b oder nicht-Trip-Pushes wie
    /// mailcontrol) landen in `looseNotifications` und müssen separat
    /// behandelt werden.
    ///
    /// Returns:
    ///   - groups: Trip-Gruppen, sortiert nach lastUpdate DESC (neueste zuerst)
    ///   - loose: Einzelne Notifications ohne tripKey, sortiert nach receivedAt DESC
    static func group(
        _ notifications: [StoredNotification]
    ) -> (groups: [TripGroup], loose: [StoredNotification]) {
        var byKey: [String: [StoredNotification]] = [:]
        var loose: [StoredNotification] = []

        for n in notifications {
            if let key = n.tripKey {
                byKey[key, default: []].append(n)
            } else {
                loose.append(n)
            }
        }

        let groups: [TripGroup] = byKey.compactMap { key, items in
            // Chronologisch sortieren (älteste zuerst für die History)
            let sorted = items.sorted { $0.receivedAt < $1.receivedAt }
            guard let newest = sorted.last else { return nil }

            return TripGroup(
                id: key,
                tripKey: key,
                line: newest.trainLine,
                trainNumber: newest.trainNumber,
                direction: newest.destination,
                plannedDeparture: newest.plannedDeparture,
                plannedPlatform: newest.plannedPlatform,
                routeId: newest.routeId,
                fromStation: newest.fromStation,
                toStation: newest.toStation,
                currentStatus: newest.currentStatus ?? newest.statusRaw,
                currentDelayMinutes: newest.currentDelayMinutes ?? newest.delayMinutes,
                currentPlatform: newest.currentPlatform ?? newest.plannedPlatform,
                lastUpdate: newest.receivedAt,
                events: sorted
            )
        }
        .sorted { $0.lastUpdate > $1.lastUpdate }

        let sortedLoose = loose.sorted { $0.receivedAt > $1.receivedAt }

        return (groups, sortedLoose)
    }
}
