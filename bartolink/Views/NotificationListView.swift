//
//  NotificationListView.swift
//  bartolink
//
//  Liste aller empfangenen Push-Notifications.
//  Gruppiert nach Tag, neueste oben.
//

import SwiftUI
import SwiftData


struct NotificationListView: View {
    
    @Query(sort: \StoredNotification.receivedAt, order: .reverse)
    private var notifications: [StoredNotification]
    
    @Environment(\.modelContext) private var modelContext
    
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView()
                
                if notifications.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                if !notifications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                deleteAll()
                            } label: {
                                Label("Alle löschen", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Sections
    
    @ViewBuilder
    private var listContent: some View {
        let grouped = groupByDay(notifications)
        
        List {
            ForEach(grouped, id: \.title) { section in
                Section(section.title) {
                    // Aufbau der Liste mit Notifications
                    ForEach(section.items) { item in
                        ZStack {
                            NotificationRow(notification: item)
                            NavigationLink(destination: NotificationDetailView(notification: item)) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                    }
                    .onDelete { offsets in
                        delete(in: section.items, at: offsets)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)   // damit BackgroundView durchscheint
    }
    
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Keine Notifications")
                .font(.title3.bold())
            Text("Sobald ein Tool einen Push schickt,\nlandet er hier.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .padding()
    }
    
    
    // MARK: - Grouping
    
    private struct DaySection {
        let title: String
        let items: [StoredNotification]
    }
    
    private func groupByDay(_ items: [StoredNotification]) -> [DaySection] {
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: items) { item -> Date in
            calendar.startOfDay(for: item.receivedAt)
        }
        
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, items) in
                DaySection(
                    title: formatDate(date),
                    items: items
                )
            }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Heute" }
        if calendar.isDateInYesterday(date) { return "Gestern" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: date).capitalized
    }
    
    
    // MARK: - Delete
    
    private func delete(in items: [StoredNotification], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
    
    private func deleteAll() {
        for item in notifications {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}


// MARK: - Row

private struct NotificationRow: View {
    
    let notification: StoredNotification
    
    var body: some View {
        let style = Theme.style(for: notification.source)
        
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: style.symbol)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(style.color.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(timeText(notification.receivedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Text(notification.source)
                    .font(.caption2.bold())
                    .foregroundStyle(style.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(style.color.opacity(0.15), in: Capsule())
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(
            Color.white.opacity(0.6).background(.ultraThinMaterial)
        )
    }
    
    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}


#Preview {
    NotificationListView()
        .modelContainer(for: StoredNotification.self, inMemory: true)
}
