//
//  ContentView.swift
//  bartolink
//

import SwiftUI
import SwiftData


struct ContentView: View {

    @EnvironmentObject var tokenStore: PushTokenStore

    var body: some View {
        TabView {
            NotificationListView()
                .tabItem {
                    Label("Inbox", systemImage: "tray.fill")
                }

            StatusView()
                .tabItem {
                    Label("Status", systemImage: "antenna.radiowaves.left.and.right")
                }
        }
        .tint(.blue)
    }
}


#Preview {
    ContentView()
        .environmentObject(PushTokenStore.shared)
        .modelContainer(for: StoredNotification.self, inMemory: true)
}
