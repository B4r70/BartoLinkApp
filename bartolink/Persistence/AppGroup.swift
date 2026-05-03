//
//  AppGroup.swift
//  bartolink
//
//  Created by Barto on 03.05.26.
//


//
//  AppGroup.swift
//  bartolink
//
//  Zentrale Stelle für alles, was zwischen App und Notification Service Extension
//  geteilt werden muss.
//

import Foundation

enum AppGroup {
    
    /// Die App Group-ID. Muss in beiden Targets in den Capabilities aktiviert sein.
    static let identifier = "group.com.barto.bartolink"
    
    /// Verzeichnis, in dem App und Extension gemeinsam Daten ablegen.
    /// Crash hier wäre ein Konfigurationsfehler — fail fast, statt still falsch zu speichern.
    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else {
            fatalError("App Group \(identifier) ist nicht verfügbar — Capability fehlt?")
        }
        return url
    }
    
    /// Pfad zur SwiftData-Datenbank im geteilten Container.
    static var swiftDataStoreURL: URL {
        containerURL.appendingPathComponent("BartoLinkStore.sqlite")
    }
}