//
//  StatusView.swift
//  bartolink
//
//  Diagnose-Tab: Health-Hero, APNs-Token, Backend-Verbindung, App-Info.
//

import SwiftUI


struct StatusView: View {

    @EnvironmentObject var tokenStore: PushTokenStore

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        healthHero
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        apnsCard
                            .padding(.horizontal, 20)

                        backendCard
                            .padding(.horizontal, 20)

                        appCard
                            .padding(.horizontal, 20)

                        Color.clear.frame(height: 110)   // Platz für Tab-Bar-Overlay
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
        }
    }


    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                SLLabel("System · Live", color: Theme.ink2)
                Text("Status")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.7)
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            SLChip(text: healthLabel, color: healthColor)
        }
        .padding(.vertical, 8)
    }


    // MARK: - Health Hero

    private var healthHero: some View {
        SLCard(padding: 0) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    SLLabel("● Alle Systeme nominal", color: Theme.accentGreen)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("99,8")
                            .font(.system(size: 36, weight: .bold))
                            .tracking(-0.79)
                            .foregroundStyle(Theme.ink)
                        Text("% Uptime")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.ink3)
                    }
                    .padding(.top, 2)

                    SLSparkline(values: sparklineValues, color: Theme.accentGreen)
                        .frame(height: 50)
                        .padding(.top, 6)

                    HStack {
                        Text("−30 Tage")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Theme.ink3)
                        Spacer()
                        Text("Jetzt")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Theme.ink3)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 14)
                .background(
                    LinearGradient(
                        colors: [Theme.accentGreen.tinted(0.16), Theme.cardFill],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)

                HStack(spacing: 0) {
                    SLKPI(label: "Latenz", value: "84", sub: "ms · p50")
                    SLKPI(label: "Pushes", value: "12", sub: "heute", divider: true)
                    SLKPI(label: "Queue", value: "0", sub: "pending", divider: true)
                }
            }
        }
    }

    private var sparklineValues: [CGFloat] {
        [12, 18, 16, 22, 20, 28, 24, 32, 26, 30, 22, 34, 28, 36, 30]
    }


    // MARK: - APNs

    private var apnsCard: some View {
        SLCard(accent: Theme.accentBlue) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SLLabel("APNs")
                    Spacer()
                    SLChip(text: apnsChipText, color: apnsChipColor)
                }

                if let token = tokenStore.token {
                    Text(token)
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundStyle(Theme.ink2)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0.06, green: 0.13, blue: 0.24).opacity(0.04))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Theme.hairline, lineWidth: 1)
                        }
                        .textSelection(.enabled)
                } else if let err = tokenStore.registrationError {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.accentRed)
                } else {
                    Text("Registriere bei Apple…")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.ink2)
                }
            }
        }
    }

    private var apnsChipText: String {
        if tokenStore.token != nil { return "Registriert" }
        if tokenStore.registrationError != nil { return "Fehler" }
        return "Wartet…"
    }

    private var apnsChipColor: Color {
        if tokenStore.token != nil { return Theme.accentGreen }
        if tokenStore.registrationError != nil { return Theme.accentRed }
        return Theme.ink3
    }


    // MARK: - Backend

    private var backendCard: some View {
        SLCard(accent: Theme.accentGreen) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SLLabel("Backend")
                    Spacer()
                    SLChip(text: backendChipText, color: backendChipColor)
                }

                VStack(spacing: 0) {
                    SLKeyValue(key: "Device", value: backendDeviceText)
                    SLKeyValue(
                        key: "Endpoint",
                        value: Config.backendURL.host ?? Config.backendURL.absoluteString,
                        mono: true
                    )
                    SLKeyValue(key: "Environment", value: Config.apnsEnvironment, last: true)
                }
                .padding(.top, 4)
            }
        }
    }

    private var backendChipText: String {
        switch tokenStore.backendStatus {
        case .idle:               return "Wartet"
        case .registering:        return "Verbindet…"
        case .registered:         return "Verbunden"
        case .failed:             return "Fehler"
        }
    }

    private var backendChipColor: Color {
        switch tokenStore.backendStatus {
        case .idle, .registering: return Theme.ink3
        case .registered:         return Theme.accentGreen
        case .failed:             return Theme.accentRed
        }
    }

    private var backendDeviceText: String {
        switch tokenStore.backendStatus {
        case .registered(let id): return "#\(id)"
        case .failed(let msg):    return msg
        default:                  return "—"
        }
    }


    // MARK: - App

    private var appCard: some View {
        SLCard {
            VStack(alignment: .leading, spacing: 8) {
                SLLabel("App")

                VStack(spacing: 0) {
                    SLKeyValue(key: "Bundle-ID", value: Config.bundleID, mono: true)
                    SLKeyValue(key: "Version", value: appVersionString)
                    SLKeyValue(key: "APNs-Env", value: Config.apnsEnvironment, last: true)
                }
                .padding(.top, 4)
            }
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }


    // MARK: - Health summary

    private var healthLabel: String {
        if tokenStore.token != nil,
           case .registered = tokenStore.backendStatus { return "Healthy" }
        if case .failed = tokenStore.backendStatus { return "Fehler" }
        if tokenStore.registrationError != nil { return "Fehler" }
        return "Wartet…"
    }

    private var healthColor: Color {
        if tokenStore.token != nil,
           case .registered = tokenStore.backendStatus { return Theme.accentGreen }
        if case .failed = tokenStore.backendStatus { return Theme.accentRed }
        if tokenStore.registrationError != nil { return Theme.accentRed }
        return Theme.ink3
    }
}


#Preview {
    StatusView()
        .environmentObject(PushTokenStore.shared)
}
