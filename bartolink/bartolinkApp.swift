//
//  bartolinkApp.swift
//  bartolink
//

import SwiftUI
import SwiftData
import os.log


@main
struct BartolinkApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var tokenStore = PushTokenStore.shared

    private let logger = Logger(subsystem: "com.barto.bartolink", category: "App")


        // MARK: - SwiftData Container

    let modelContainer: ModelContainer = {
        let schema = Schema([StoredNotification.self])
        let config = ModelConfiguration(
            schema: schema,
            url: AppGroup.swiftDataStoreURL
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Konnte SwiftData-Container nicht erzeugen: \(error)")
        }
    }()

        // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tokenStore)
                .modelContainer(modelContainer)
                .onChange(of: tokenStore.token) { _, newValue in
                    if let token = newValue {
                        Task { await registerWithBackend(token: token) }
                    }
                }
        }
    }


        // MARK: - Backend-Registrierung

    @MainActor
    private func registerWithBackend(token: String) async {
        logger.info("Registriere Token beim Backend…")
        tokenStore.backendStatus = .registering

        do {
            let response = try await APIClient.shared.registerToken(token)
            logger.info("✅ Backend-Registrierung erfolgreich: id=\(response.id)")
            tokenStore.backendStatus = .registered(id: response.id)
        } catch {
            logger.error("❌ Backend-Registrierung fehlgeschlagen: \(error.localizedDescription)")
            tokenStore.backendStatus = .failed(message: error.localizedDescription)
        }
    }
}
