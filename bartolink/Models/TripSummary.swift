//
//  TripDTOs.swift
//  bartolink
//
//  Sprint 3b — DTOs für Trip-Endpoints.
//
//  Korrespondiert mit barto-link's src/models.py:
//    - TripSummary
//    - TripRefreshResponse
//    - TripRefreshThrottled (HTTP 429)
//

import Foundation


// MARK: - TripSummary

/// Aktueller Stand eines Trips, wie ihn das Backend liefert.
/// Enthält die wichtigsten Felder für Inbox + DetailView-Header.
struct TripSummary: Decodable {
    let trip_key: String
    let line: String
    let train_number: String
    let direction: String
    let route_id: String
    let planned_departure: String       // "HH:MM"
    let current_status: String          // "on_time" | "delayed" | "cancelled" | "not_found"
    let current_delay_min: Int?
    let current_platform: String?
    let last_update_at: String          // ISO-Datum
}


// MARK: - Refresh-Endpoint

/// HTTP 200: Refresh erfolgreich.
struct TripRefreshResponse: Decodable {
    let trip: TripSummary
    let refreshed_at: String                // ISO-Datum
    let next_refresh_allowed_at: String     // ISO-Datum
}


/// HTTP 429: Refresh wurde durch Rate-Limit geblockt.
struct TripRefreshThrottled: Decodable, Error {
    let retry_after_seconds: Int
    let reason: String                      // "per_trip" | "global"

    var localizedDescription: String {
        switch reason {
        case "per_trip":
            return "Bitte \(retry_after_seconds)s warten — Trip wurde gerade aktualisiert."
        case "global":
            return "Bitte \(retry_after_seconds)s warten — zu viele Refreshes in der letzten Stunde."
        default:
            return "Bitte \(retry_after_seconds)s warten."
        }
    }
}
