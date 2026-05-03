//
//  NotificationService.swift
//  BartolinkNotificationService
//
//  Wird bei jedem ankommenden Push aufgeweckt — auch bei geschlossener App.
//  Speichert die Notification in der gemeinsamen SwiftData-DB,
//  bevor iOS das Banner anzeigt.
//

import UserNotifications
import SwiftData
import os.log


final class NotificationService: UNNotificationServiceExtension {

    private let logger = Logger(
        subsystem: "com.barto.bartolink",
        category: "NotificationService"
    )

    /// Apples Pattern: Bei drohendem Timeout (~30 Sek.) ruft iOS serviceExtensionTimeWillExpire().
    /// Wir müssen dann das aktuelle Best-Effort-Resultat ausliefern.
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?


    // MARK: - Entry Point

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let content = bestAttemptContent else {
            logger.error("Konnte mutableCopy von Notification-Content nicht erstellen.")
            contentHandler(request.content)
            return
        }

        // Inbox-Persistenz; Fehler nur loggen, niemals den Push verschlucken.
        do {
            try persistToInbox(userInfo: content.userInfo)
            logger.info("Notification in Inbox gespeichert: \(content.title, privacy: .public)")
        } catch {
            logger.error("Inbox-Save fehlgeschlagen: \(error.localizedDescription, privacy: .public)")
        }

        // Banner anzeigen lassen — egal ob Save geklappt hat
        contentHandler(content)
    }


    // MARK: - Timeout-Handler

    override func serviceExtensionTimeWillExpire() {
        // Letzte Chance: liefere aus, was wir haben
        if let contentHandler, let bestAttemptContent {
            logger.warning("Extension-Timeout — liefere Best-Effort-Content aus.")
            contentHandler(bestAttemptContent)
        }
    }


    // MARK: - SwiftData-Persistenz

    /// Schreibt die Notification in den App-Group-SwiftData-Container.
    /// Wirft, wenn Container-Init oder Save fehlschlägt.
    private func persistToInbox(userInfo: [AnyHashable: Any]) throws {
        guard let notification = StoredNotification.fromAPNsUserInfo(userInfo) else {
            logger.warning("APNs-Payload hat nicht das erwartete Format — überspringe Save.")
            return
        }

        let schema = Schema([StoredNotification.self])
        let config = ModelConfiguration(schema: schema, url: AppGroup.swiftDataStoreURL)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        context.insert(notification)
        try context.save()
    }
}
