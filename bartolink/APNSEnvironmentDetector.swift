//
//  APNSEnvironmentDetector.swift
//  bartolink
//
//  Created by Barto on 01.05.26.
//


//
//  APNSEnvironmentDetector.swift
//  bartolink
//
//  Liest das `aps-environment`-Entitlement aus dem eingebetteten
//  Provisioning Profile, um zur Laufzeit zu bestimmen, ob wir
//  Sandbox- oder Production-Tokens bekommen.
//
//  Hintergrund: Compile-Flags wie #if DEBUG sind unzuverlässig, weil
//  ein Xcode-Run mit Release-Configuration trotzdem das Development-
//  Provisioning-Profile nutzt → Sandbox-Token. Nur der TestFlight-
//  oder App-Store-Pfad bringt ein Distribution-Profile → Production.
//

import Foundation
import os.log


enum APNSEnvironmentDetector {
    
    private static let logger = Logger(subsystem: "com.barto.bartolink", category: "APNS")
    
    
    /// Bestimmt das APNs-Environment, das der Backend für diesen Build nutzen soll.
    ///
    /// Reihenfolge der Erkennung:
    /// 1. Liest `embedded.mobileprovision` (Provisioning Profile in der App)
    /// 2. Extrahiert `aps-environment` aus den Entitlements darin
    /// 3. Mappt:  "development" → "sandbox", "production" → "production"
    ///
    /// Wenn nichts gefunden wird (z.B. Simulator), fällt auf Sandbox zurück
    /// — das ist der sichere Default für Entwicklung.
    static func detect() -> String {
        guard let profile = loadProvisioningProfile() else {
            logger.warning("Kein Provisioning Profile gefunden — Fallback: sandbox")
            return "sandbox"
        }
        
        guard let entitlements = profile["Entitlements"] as? [String: Any] else {
            logger.warning("Provisioning Profile ohne Entitlements — Fallback: sandbox")
            return "sandbox"
        }
        
        guard let apsEnv = entitlements["aps-environment"] as? String else {
            logger.warning("Kein aps-environment-Eintrag — Fallback: sandbox")
            return "sandbox"
        }
        
        // Apple's Wert "development" mappen wir auf unser "sandbox",
        // "production" bleibt "production".
        let result = (apsEnv == "development") ? "sandbox" : "production"
        logger.info("APNs-Environment erkannt: \(apsEnv, privacy: .public) → \(result, privacy: .public)")
        return result
    }
    
    
    // MARK: - Private
    
    /// Lädt das embedded.mobileprovision aus dem App-Bundle und parst es als Plist.
    /// Format: PKCS#7-signed Plist — wir extrahieren den Plist-Block per Marker-Suche.
    private static func loadProvisioningProfile() -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision") else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        // Plist-Anfang/Ende in der signed Datei suchen
        guard
            let start = data.range(of: Data("<?xml".utf8)),
            let end = data.range(of: Data("</plist>".utf8))
        else {
            return nil
        }
        
        let plistData = data.subdata(in: start.lowerBound..<end.upperBound)
        
        return try? PropertyListSerialization.propertyList(
            from: plistData,
            options: [],
            format: nil
        ) as? [String: Any]
    }
}