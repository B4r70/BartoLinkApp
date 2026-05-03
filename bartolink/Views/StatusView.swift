//
//  StatusView.swift
//  bartolink
//
//  Diagnose-Tab: zeigt APNs-Token, Backend-Verbindung, App-Version.
//

import SwiftUI


struct StatusView: View {
    
    @EnvironmentObject var tokenStore: PushTokenStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()
                
                List {
                    Section("APNs") {
                        if let token = tokenStore.token {
                            Label("Token registriert", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Device-Token")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(token.prefix(32) + "…")
                                    .font(.system(.caption, design: .monospaced))
                            }
                        } else if let error = tokenStore.registrationError {
                            Label(error, systemImage: "xmark.octagon.fill")
                                .foregroundStyle(.red)
                        } else {
                            Label("Registriere bei Apple…", systemImage: "icloud.and.arrow.down")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.6).background(.ultraThinMaterial))
                    
                    Section("Backend") {
                        switch tokenStore.backendStatus {
                        case .idle:
                            Label("Wartet auf Token", systemImage: "ellipsis.circle")
                                .foregroundStyle(.secondary)
                        case .registering:
                            HStack {
                                ProgressView()
                                Text("Verbinde mit push.barto.cloud…")
                                    .foregroundStyle(.secondary)
                            }
                        case .registered(let id):
                            Label("Verbunden (Device #\(id))", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        case .failed(let message):
                            VStack(alignment: .leading) {
                                Label("Verbindung fehlgeschlagen", systemImage: "xmark.octagon.fill")
                                    .foregroundStyle(.red)
                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.6).background(.ultraThinMaterial))
                    
                    Section("App") {
                        LabeledContent("Bundle-ID", value: Config.bundleID)
                        LabeledContent("Backend-URL", value: Config.backendURL.absoluteString)
                        LabeledContent("APNs-Env", value: Config.apnsEnvironment)
                    }
                    .listRowBackground(Color.white.opacity(0.6).background(.ultraThinMaterial))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Status")
        }
    }
}


#Preview {
    StatusView()
        .environmentObject(PushTokenStore.shared)
}
