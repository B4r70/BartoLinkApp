//
//  ContentView.swift
//  bartolink
//
//  Sprint 3b: NotificationListView → TripListView
//

import SwiftUI
import SwiftData


struct ContentView: View {

    @EnvironmentObject var tokenStore: PushTokenStore
    @State private var selection: SLTab = .inbox

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .inbox:
                    TripListView()
                case .status:
                    StatusView()
                }
            }
            .transition(.opacity)

            SLTabBar(selection: $selection)
                .padding(.bottom, 18)
        }
        .ignoresSafeArea(.keyboard)
    }
}


#Preview {
    ContentView()
        .environmentObject(PushTokenStore.shared)
        .modelContainer(for: StoredNotification.self, inMemory: true)
}
