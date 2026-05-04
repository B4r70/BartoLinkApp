    //
    //  AppDelegate.swift
    //  bartolink
    //
    //  Push-Notification-Hooks: registriert beim System,
    //  empfängt Tokens und Notifications.
    //

import UIKit
import Combine    // ← bringt Combine + ObservableObject mit
import os.log


/// Globaler Speicher für den aktuellen Push-Token + Registrierungs-Status.
final class PushTokenStore: ObservableObject {
    static let shared = PushTokenStore()

    @Published var token: String?
    @Published var registrationError: String?
    @Published var backendStatus: BackendStatus = .idle

    enum BackendStatus: Equatable {
        case idle                     // noch nichts versucht
        case registering              // läuft gerade
        case registered(id: Int)      // erfolgreich
        case failed(message: String)  // Fehler
    }

    private init() {}
}


final class AppDelegate: NSObject, UIApplicationDelegate {

    private let logger = Logger(subsystem: "com.barto.bartolink", category: "PushSetup")

        // MARK: - App-Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("App gestartet, registriere für Remote-Notifications…")

            // Permission anfragen, dann beim System für APNs registrieren
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            guard let self = self else { return }

            if let error = error {
                self.logger.error("Authorization-Fehler: \(error.localizedDescription)")
                return
            }

            self.logger.info("Permission granted: \(granted)")

            if granted {
                    // WICHTIG: Auf MainThread, weil UIKit-API
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }

        return true
    }


        // MARK: - APNs Token Callbacks

        /// Wird aufgerufen, wenn Apple uns einen Token gegeben hat.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
            // Der Token kommt als Data — wir brauchen ihn als Hex-String
            // (das ist das Format, das wir an APNs zurückgeben).
        let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()

        logger.info("✅ APNs-Token erhalten: \(tokenHex, privacy: .public)")
        print("=====================================================")
        print("APNS DEVICE TOKEN (zum Kopieren):")
        print(tokenHex)
        print("=====================================================")

        DispatchQueue.main.async {
            PushTokenStore.shared.token = tokenHex
            PushTokenStore.shared.registrationError = nil
        }
    }

        /// Wird aufgerufen, wenn die Registrierung fehlschlug.
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("❌ APNs-Registrierung fehlgeschlagen: \(error.localizedDescription)")

        DispatchQueue.main.async {
            PushTokenStore.shared.registrationError = error.localizedDescription
        }
    }
}


    // MARK: - Notification Display

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logger.info("Notification empfangen (foreground): \(notification.request.identifier)")

        // In SwiftData persistieren
        store(notification: notification)

        completionHandler([.banner, .sound, .badge])
    }


    /// Wird aufgerufen, wenn der User auf eine Notification tippt.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logger.info("Notification getappt: \(response.notification.request.identifier)")

        // Auch hier speichern (z.B. wenn App komplett zu war und User direkt von Lockscreen tappt)
        store(notification: response.notification)

        completionHandler()
    }
    
    
        // MARK: - Persistenz
    
        /// Persistenz übernimmt jetzt die Notification Service Extension.
        /// Diese Methode bleibt als Hook für zukünftige Foreground-Logik
        /// (z.B. Inbox-Badge aktualisieren, lokale Banner-Sounds, etc).
    private func store(notification: UNNotification) {
            // Bewusst leer — Doppel-Save vermeiden.
    }
}
