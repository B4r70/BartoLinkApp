//
//  StoredNotification.swift
//  bartolink
//
//  SwiftData-Persistenz für eingehende Notifications.
//  Jeder Push wird hier gespeichert für die Inbox-Verlaufsansicht.
//
//  Sprint 3b: Erweitert um Trip-Felder, damit Notifications nach `tripKey`
//  gruppiert werden können (Inbox-Trip-Gruppierung) und die DetailView
//  den vollständigen Trip-Stand rendern kann.
//

import Foundation
import SwiftData


@Model
final class StoredNotification {

    // MARK: - Stored Properties (Basis)

    var id: UUID
    var title: String
    var body: String
    var source: String
    var receivedAt: Date
    var isRead: Bool


    // MARK: - Stored Properties (Train-Metadaten — Pre-Sprint-3b)
    // Alle optional, damit ältere Notifications ohne Migration weiter funktionieren

    var trainLine: String?
    var trainNumber: String?
    var destination: String?
    var plannedDeparture: Date?
    var actualDeparture: Date?
    var delayMinutes: Int?
    var plannedPlatform: String?
    var delayReason: String?
    var delayReasonSeverity: String?
    var fromStation: String?
    var toStation: String?
    var statusRaw: String?


    // MARK: - Stored Properties (Trip-Aggregation — Sprint 3b)
    // Werden aus dem `meta`-Dict des Pushes gelesen.
    // Optional, damit alte StoredNotifications weiter funktionieren.

    /// Eindeutige Trip-Identifikation. Format: "{train_number}_{date}_{route_id}"
    /// z.B. "12623_2026-05-04_zurueck-1616"
    /// Notifications mit demselben tripKey gehören zur selben Fahrt.
    var tripKey: String?

    /// dbticker-Route-ID (z.B. "zurueck-1616") — für den Refresh-Button.
    var routeId: String?

    /// Aktuelles Gleis (kann von plannedPlatform abweichen → Gleisänderung).
    var currentPlatform: String?

    /// Event-Typ dieser einzelnen Notification (für die History-Liste):
    /// "delay" | "platform_change" | "cancelled" | "on_time" | "not_found" | "manual_refresh"
    var eventType: String?

    /// Server-seitige Event-ID. Wird beim Deduplizieren von Pushes genutzt
    /// (z.B. wenn iOS denselben Push aus Sandbox + Production erhält).
    var eventId: Int?

    /// Aktueller Trip-Status zum Zeitpunkt des Pushes.
    var currentStatus: String?

    /// Aktuelle Verspätung in Min — kann sich von delayMinutes (event-spezifisch)
    /// unterscheiden, wenn das Event eine Gleisänderung war.
    var currentDelayMinutes: Int?


    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        source: String,
        receivedAt: Date = .now,
        isRead: Bool = false,
        trainLine: String? = nil,
        trainNumber: String? = nil,
        destination: String? = nil,
        plannedDeparture: Date? = nil,
        actualDeparture: Date? = nil,
        delayMinutes: Int? = nil,
        plannedPlatform: String? = nil,
        delayReason: String? = nil,
        delayReasonSeverity: String? = nil,
        fromStation: String? = nil,
        toStation: String? = nil,
        statusRaw: String? = nil,
        tripKey: String? = nil,
        routeId: String? = nil,
        currentPlatform: String? = nil,
        eventType: String? = nil,
        eventId: Int? = nil,
        currentStatus: String? = nil,
        currentDelayMinutes: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.source = source
        self.receivedAt = receivedAt
        self.isRead = isRead
        self.trainLine = trainLine
        self.trainNumber = trainNumber
        self.destination = destination
        self.plannedDeparture = plannedDeparture
        self.actualDeparture = actualDeparture
        self.delayMinutes = delayMinutes
        self.plannedPlatform = plannedPlatform
        self.delayReason = delayReason
        self.delayReasonSeverity = delayReasonSeverity
        self.fromStation = fromStation
        self.toStation = toStation
        self.statusRaw = statusRaw
        self.tripKey = tripKey
        self.routeId = routeId
        self.currentPlatform = currentPlatform
        self.eventType = eventType
        self.eventId = eventId
        self.currentStatus = currentStatus
        self.currentDelayMinutes = currentDelayMinutes
    }


    // MARK: - Computed

    /// Hat diese Notification überhaupt Zug-Metadaten? Wenn nicht, brauchen wir
    /// keine DetailView aufzumachen.
    var hasTrainMetadata: Bool {
        trainLine != nil || trainNumber != nil || delayMinutes != nil
    }

    /// Verspätet laut Metadaten? (currentDelayMinutes > 0 oder statusRaw == "delayed")
    var isDelayed: Bool {
        if let d = currentDelayMinutes ?? delayMinutes, d > 0 { return true }
        if (currentStatus ?? statusRaw)?.lowercased() == "delayed" { return true }
        return false
    }

    /// Hat diese Notification Trip-Aggregations-Daten?
    /// (Pushes vor Sprint 3b haben das nicht.)
    var isTripPush: Bool {
        tripKey != nil
    }

    /// Eignet sich diese Notification für die Live-Hero-Karte oben in der Inbox?
    /// Kriterien: Zug-Metadaten + verspätet + jung (< 30 Min) + Abfahrt < 60 Min
    /// in der Zukunft.
    var liveHeroEligible: Bool {
        guard hasTrainMetadata, isDelayed else { return false }

        let now = Date()
        guard now.timeIntervalSince(receivedAt) < 30 * 60 else { return false }

        let reference = plannedDeparture ?? actualDeparture
        if let dep = reference {
            let diff = dep.timeIntervalSince(now)
            return diff > -5 * 60 && diff < 60 * 60
        }
        return true
    }
}


// MARK: - Convenience: APNs Payload Parsing

extension StoredNotification {

    /// Erstellt aus einem APNs-Payload-Dictionary.
    /// Erwartet das Format aus barto-link's `_build_trip_meta`:
    ///   { aps: { alert: { title, body } }, source: ..., meta: { ... } }
    static func fromAPNsUserInfo(_ userInfo: [AnyHashable: Any]) -> StoredNotification? {
        guard
            let aps = userInfo["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any],
            let title = alert["title"] as? String,
            let body = alert["body"] as? String
        else {
            return nil
        }

        let source = (userInfo["source"] as? String) ?? "unknown"
        let meta = userInfo["meta"] as? [String: Any]

        // --- Train-Felder (Backwards-Compat) ---
        let trainLine = meta?["train_line"] as? String ?? meta?["line"] as? String
        let trainNumber = meta?["train_number"] as? String
        let destination = meta?["destination"] as? String ?? meta?["direction"] as? String
        let plannedDeparture = parsePlannedDeparture(meta?["planned_departure"])
        let actualDeparture = parseISODate(meta?["actual_departure"] as? String)
        let plannedPlatform = meta?["planned_platform"] as? String

        // --- Trip-Aggregation (Sprint 3b) ---
        let tripKey = meta?["trip_key"] as? String
        let routeId = meta?["route_id"] as? String
        let currentPlatform = meta?["current_platform"] as? String
        let eventType = meta?["event_type"] as? String
        let eventId = meta?["event_id"] as? Int
        let currentStatus = meta?["current_status"] as? String
        let currentDelayMinutes = meta?["current_delay_min"] as? Int

        // Event-spezifische Verspätung (für die History-Zeile)
        let eventDelayMinutes = meta?["event_delay_min"] as? Int
            ?? meta?["delay_minutes"] as? Int

        // Stations
        let fromStation = meta?["from_station"] as? String
            ?? meta?["departure_station"] as? String
        let toStation = meta?["to_station"] as? String
            ?? meta?["arrival_station"] as? String

        return StoredNotification(
            title: title,
            body: body,
            source: source,
            trainLine: trainLine,
            trainNumber: trainNumber,
            destination: destination,
            plannedDeparture: plannedDeparture,
            actualDeparture: actualDeparture,
            delayMinutes: eventDelayMinutes,
            plannedPlatform: plannedPlatform,
            delayReason: meta?["delay_reason"] as? String
                ?? meta?["event_message"] as? String,
            delayReasonSeverity: meta?["delay_reason_severity"] as? String,
            fromStation: fromStation,
            toStation: toStation,
            statusRaw: meta?["status"] as? String ?? currentStatus,
            tripKey: tripKey,
            routeId: routeId,
            currentPlatform: currentPlatform,
            eventType: eventType,
            eventId: eventId,
            currentStatus: currentStatus,
            currentDelayMinutes: currentDelayMinutes
        )
    }

    /// `planned_departure` kommt von barto-link entweder als ISO-String
    /// oder als "HH:MM"-String (in Trip-Pushes seit Sprint 3a).
    /// Wir versuchen beide Formate.
    private static func parsePlannedDeparture(_ raw: Any?) -> Date? {
        guard let raw else { return nil }

        if let s = raw as? String {
            // ISO 8601 erst probieren
            if let d = parseISODate(s) { return d }

            // Sonst "HH:MM" — kombinieren mit "heute" in Berlin-Zeit
            return parseHHMMToday(s)
        }
        return nil
    }

    private static func parseHHMMToday(_ s: String) -> Date? {
        let parts = s.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1])
        else { return nil }

        let berlin = TimeZone(identifier: "Europe/Berlin") ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = berlin

        return calendar.date(
            bySettingHour: hour, minute: minute, second: 0,
            of: Date()
        )
    }

    private static func parseISODate(_ s: String?) -> Date? {
        guard let s else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: s) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: s)
    }
}
