//
//  RefreshButton.swift
//  bartolink
//
//  Created by Barto on 04.05.26.
//


//
//  RefreshButton.swift
//  bartolink
//
//  Sprint 3b — Refresh-Button mit Cooldown-State.
//
//  Visualisiert den TripRefreshController-State als Button.
//  Drei sichtbare Modi:
//    - idle:        "Aktualisieren" (klickbar)
//    - loading:     Spinner (disabled)
//    - cooldown(N): "Aktualisieren in Ns" (disabled)
//    - error:       "Erneut versuchen" (klickbar, rot)
//
//  Optional disabled von außen — z.B. wenn der Trip nicht von heute ist.
//

import SwiftUI


struct RefreshButton: View {

    let tripKey: String
    var disabled: Bool = false
    var disabledHint: String? = nil

    @ObservedObject var controller: TripRefreshController


    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                guard !disabled else { return }
                Task { await controller.refresh(tripKey: tripKey) }
            } label: {
                buttonContent
            }
            .buttonStyle(.plain)
            .disabled(!isInteractive)

            if let hint = effectiveHint {
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundStyle(hintColor)
            }
        }
    }


    // MARK: - Subviews

    private var buttonContent: some View {
        HStack(spacing: 8) {
            iconView
            Text(label)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(background)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(stroke, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch controller.state {
        case .loading:
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
                .tint(foreground)

        case .cooldown:
            Image(systemName: "clock")
                .font(.system(size: 14, weight: .semibold))

        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))

        case .idle:
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 14, weight: .semibold))
        }
    }


    // MARK: - State-Mapping

    private var isInteractive: Bool {
        guard !disabled else { return false }
        return controller.isInteractive
    }

    private var label: String {
        if disabled { return "Aktualisieren" }
        switch controller.state {
        case .idle:                                    return "Aktualisieren"
        case .loading:                                 return "Aktualisiere…"
        case .cooldown(let s):                         return "Aktualisieren in \(s)s"
        case .error:                                   return "Erneut versuchen"
        }
    }

    private var foreground: Color {
        if disabled { return Theme.ink3 }
        switch controller.state {
        case .error:        return Theme.accentRed
        case .cooldown:     return Theme.ink3
        case .loading:      return Theme.ink2
        case .idle:         return .white
        }
    }

    private var background: Color {
        if disabled { return Color.white.opacity(0.5) }
        switch controller.state {
        case .idle:         return Theme.accentBlue
        case .loading:      return Color.white.opacity(0.7)
        case .cooldown:     return Color.white.opacity(0.5)
        case .error:        return Color.white.opacity(0.7)
        }
    }

    private var stroke: Color {
        if disabled { return Theme.hairline }
        switch controller.state {
        case .idle:         return .clear
        case .error:        return Theme.accentRed.opacity(0.4)
        default:            return Theme.hairline
        }
    }


    // MARK: - Hint unter dem Button

    private var effectiveHint: String? {
        if disabled, let hint = disabledHint { return hint }
        if case .error(let msg) = controller.state { return msg }
        return nil
    }

    private var hintColor: Color {
        if case .error = controller.state { return Theme.accentRed }
        return Theme.ink3
    }
}


// MARK: - Preview

#Preview("States") {
    let idleController = TripRefreshController()
    let loadingController = TripRefreshController()
    let cooldownController: TripRefreshController = {
        let c = TripRefreshController()
        // Hack für Preview: wir können den State nicht direkt setzen,
        // aber ein Refresh-Aufruf mit fake-Tripkey wird scheitern und den
        // Error-Pfad triggern. Für echtes Testing lieber im Live-Build.
        return c
    }()

    return VStack(spacing: 16) {
        RefreshButton(tripKey: "test", controller: idleController)
        RefreshButton(tripKey: "test", controller: loadingController)
        RefreshButton(
            tripKey: "test",
            disabled: true,
            disabledHint: "Trip in der Vergangenheit",
            controller: cooldownController
        )
    }
    .padding()
    .background(Color(red: 0.85, green: 0.93, blue: 1.0))
}