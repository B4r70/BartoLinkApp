//
//  StoredNotification.swift
//  bartolink
//
//  SwiftData-Persistenz für eingehende Notifications.
//  Jeder Push wird hier gespeichert für die Verlaufsansicht.
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

    // MARK: - Stored Properties (Metadaten, optional)
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
        statusRaw: String? = nil
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
    }


    // MARK: - Computed

    /// Hat diese Notification überhaupt Zug-Metadaten? Wenn nicht, brauchen wir
    /// keine DetailView aufzumachen.
    var hasTrainMetadata: Bool {
        trainLine != nil || trainNumber != nil || delayMinutes != nil
    }
}


// MARK: - Convenience

extension StoredNotification {

    /// Erstellt aus einem APNs-Payload-Dictionary.
    /// Erwartet das Format aus apns_client.py:
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

        return StoredNotification(
            title: title,
            body: body,
            source: source,
            trainLine: meta?["train_line"] as? String,
            trainNumber: meta?["train_number"] as? String,
            destination: meta?["destination"] as? String,
            plannedDeparture: parseISODate(meta?["planned_departure"] as? String),
            actualDeparture: parseISODate(meta?["actual_departure"] as? String),
            delayMinutes: meta?["delay_minutes"] as? Int,
            plannedPlatform: meta?["planned_platform"] as? String,
            delayReason: meta?["delay_reason"] as? String,
            delayReasonSeverity: meta?["delay_reason_severity"] as? String,
            fromStation: meta?["from_station"] as? String,
            toStation: meta?["to_station"] as? String,
            statusRaw: meta?["status"] as? String
        )
    }

    private static func parseISODate(_ s: String?) -> Date? {
        guard let s else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: s) { return d }
        // Fallback ohne Bruchsekunden
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: s)
    }
}
