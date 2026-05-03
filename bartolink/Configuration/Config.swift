//
//  Config.swift
//  bartolink
//
//  ⚠️ DIESE DATEI IST .gitignore'D — niemals committen!
//  Enthält das API-Token für das Backend.
//

import Foundation


enum Config {
    
    /// URL des barto-link-Backends.
    /// - Production: https://push.barto.cloud
    /// - Local Dev (z.B. Tailscale): http://100.106.161.24:8765
    static let backendURL = URL(string: "https://push.barto.cloud")!
    
    /// API-Token für /push und /tokens/* Endpoints.
    /// Aus /etc/barto-link/barto-link.env auf bartoai → BARTO_LINK_API_TOKEN
    static let apiToken = "lC+UhOojHviNOglDc3JsuRpTsFwwMbVLbUJ4/sI4MMU="
    
    /// Bundle-ID dieser App — muss zur Registrierung an's Backend.
    /// Sollte mit dem matchen, was Apple uns als Topic akzeptiert.
    static let bundleID = "com.barto.bartolink"
    
    /// APNs-Environment dieser Build-Variante.
    /// - Debug-Builds aus Xcode → "sandbox"
    /// - TestFlight/AppStore → "production"
    /// Wird beim ersten Zugriff einmalig aus dem Provisioning Profile gelesen.
    /// Ergebnis: "sandbox" oder "production" — automatisch korrekt für jede
    /// Build-Variante (Xcode-Run, Ad-Hoc, TestFlight, App Store).
    static let apnsEnvironment: String = APNSEnvironmentDetector.detect()

    /// Optional: human-readable Label für dieses Gerät, wird beim Registrieren mitgeschickt.
    /// Wird in der Token-DB als `device_label` gespeichert (für list-Endpoint).
    static let deviceLabel = "Bartosz iPhone 16 Pro (Dev)"
}
