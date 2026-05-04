//
//  TripRefreshController.swift
//  bartolink
//
//  Sprint 3b — verwaltet den State des Refresh-Buttons:
//    - idle:          Button ist klickbar
//    - loading:       Request läuft
//    - cooldown(N):   Server hat 429 zurückgegeben, N Sekunden warten
//    - error(msg):    Letzter Versuch fehlgeschlagen (502, Netzwerk, …)
//
//  Eine Instanz pro DetailView. Hält keinen tripKey selbst — der wird beim
//  refresh()-Aufruf übergeben, damit die DetailView denselben Controller
//  auch wiederverwenden könnte (aktuell nicht nötig, aber sauberer).
//

import Foundation
import SwiftUI
import os.log
import Combine


@MainActor
final class TripRefreshController: ObservableObject {

    // MARK: - State

    enum State: Equatable {
        case idle
        case loading
        case cooldown(secondsRemaining: Int)
        case error(message: String)
    }

    @Published private(set) var state: State = .idle

    /// Ergebnis des letzten erfolgreichen Refreshs — kann von der Caller-View
    /// genutzt werden, um die UI zu aktualisieren (z.B. neuen Stand anzeigen).
    @Published private(set) var lastResponse: TripRefreshResponse?


    // MARK: - Privates

    private let logger = Logger(subsystem: "com.barto.bartolink", category: "TripRefresh")
    private var cooldownTimer: Timer?
    private var cooldownEnd: Date?


    // MARK: - Public API

    /// Kann der Button gerade gedrückt werden?
    var isInteractive: Bool {
        switch state {
        case .idle, .error: return true
        case .loading, .cooldown: return false
        }
    }

    /// Triggert einen Refresh.
    /// Bei 429 startet automatisch ein Cooldown-Countdown.
    func refresh(tripKey: String) async {
        state = .loading
        lastResponse = nil

        do {
            let response = try await APIClient.shared.refreshTrip(tripKey)
            logger.info("Refresh erfolgreich: \(response.trip.trip_key)")
            lastResponse = response
            // Eigenen Cooldown setzen — Server hat next_refresh_allowed_at geliefert.
            startCooldown(until: parseISODate(response.next_refresh_allowed_at) ?? Date().addingTimeInterval(60))
        } catch APIError.throttled(let throttle) {
            logger.info("Refresh throttled, retry in \(throttle.retry_after_seconds)s")
            startCooldown(seconds: throttle.retry_after_seconds)
        } catch {
            let message = error.localizedDescription
            logger.error("Refresh fehlgeschlagen: \(message)")
            state = .error(message: message)
        }
    }

    /// Manuelles Reset auf idle, z.B. nach Anzeige einer Fehlermeldung.
    func reset() {
        cooldownTimer?.invalidate()
        cooldownTimer = nil
        cooldownEnd = nil
        state = .idle
    }


    // MARK: - Cooldown-Mechanik

    private func startCooldown(seconds: Int) {
        startCooldown(until: Date().addingTimeInterval(TimeInterval(seconds)))
    }

    private func startCooldown(until end: Date) {
        cooldownEnd = end
        let initialRemaining = max(0, Int(end.timeIntervalSinceNow))

        if initialRemaining == 0 {
            state = .idle
            return
        }

        state = .cooldown(secondsRemaining: initialRemaining)

        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard let end = cooldownEnd else {
            cooldownTimer?.invalidate()
            cooldownTimer = nil
            state = .idle
            return
        }

        let remaining = max(0, Int(end.timeIntervalSinceNow))

        if remaining == 0 {
            cooldownTimer?.invalidate()
            cooldownTimer = nil
            cooldownEnd = nil
            state = .idle
        } else {
            state = .cooldown(secondsRemaining: remaining)
        }
    }


    // MARK: - Helpers

    private func parseISODate(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }
}
