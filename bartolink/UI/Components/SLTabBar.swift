//
//  SLTabBar.swift
//  bartolink
//
//  Custom Tab-Bar — überlagert die System-TabView (deren Bar wird ausgeblendet).
//

import SwiftUI


enum SLTab: String, CaseIterable, Identifiable {
    case inbox
    case status

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inbox:  return "Inbox"
        case .status: return "Status"
        }
    }

    var symbol: String {
        switch self {
        case .inbox:  return "tray.fill"
        case .status: return "antenna.radiowaves.left.and.right"
        }
    }
}


struct SLTabBar: View {

    @Binding var selection: SLTab

    var body: some View {
        HStack(spacing: 5) {
            ForEach(SLTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        selection = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.label)
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(-0.07)
                    }
                    .foregroundStyle(selection == tab ? Color.white : Theme.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .fill(Theme.accentBlue)
                                .matchedGeometryEffect(id: "tabPill", in: pillNS)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
        .shadow(color: Color(red: 0.06, green: 0.13, blue: 0.24).opacity(0.10),
                radius: 32, x: 0, y: 12)
        .padding(.horizontal, 16)
    }

    @Namespace private var pillNS
}


#Preview {
    struct Wrapper: View {
        @State private var sel: SLTab = .inbox
        var body: some View {
            ZStack {
                Color(red: 0.85, green: 0.93, blue: 1.0).ignoresSafeArea()
                VStack {
                    Spacer()
                    SLTabBar(selection: $sel)
                        .padding(.bottom, 18)
                }
            }
        }
    }
    return Wrapper()
}
