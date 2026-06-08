import SwiftUI

// MARK: - UC-14: Cooking History

struct HistoryTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgApp.ignoresSafeArea()
                if store.history.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 52)).foregroundStyle(Color.fg3)
                        Text("No history yet").font(.vestelH3).foregroundStyle(Color.fg1)
                        Text("Completed cooks will appear here.")
                            .font(.vestelCaption).foregroundStyle(Color.fg2)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(store.history) { entry in
                            HistoryRow(entry: entry)
                                .listRowBackground(Color.bgApp)
                                .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                                .listRowSeparatorTint(Color.line1)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("History").font(.vestelH3).foregroundStyle(Color.fg1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !store.history.isEmpty {
                        Button("Clear") { showClearAlert = true }
                            .foregroundStyle(Color.brandYellow)
                            .font(.vestelLabel)
                    }
                }
            }
            .alert("Clear history?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) { store.history.removeAll() }
            }
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(entry.session.cancelled ? Color.brandYellow : Color.success)
                .frame(width: 8, height: 8)
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.session.displayTitle)
                    .font(.vestelBody).foregroundStyle(Color.fg1)
                Text(entry.session.historyDetail)
                    .font(.vestelCaption).foregroundStyle(Color.fg3)
            }
            Spacer()
            Text(entry.formattedDate)
                .font(.vestelCaption).foregroundStyle(Color.fg3)
        }
        .padding(.vertical, 6)
    }
}
