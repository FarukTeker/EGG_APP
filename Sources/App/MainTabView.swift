import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTab = 0
    @State private var showPairingSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CookTabView()
                .tabItem { Label("Cook", systemImage: "flame.fill") }
                .tag(0)

            PresetsTabView()
                .tabItem { Label("Presets", systemImage: "list.bullet.rectangle.fill") }
                .tag(1)

            HistoryTabView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(2)

            DevicesTabView()
                .tabItem { Label("Devices", systemImage: "circle.hexagongrid.fill") }
                .tag(3)

            SettingsTabView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(Color.brandYellow)
        .background(Color.bgApp)
    }
}

// MARK: - Cook Tab wrapper

private struct CookTabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            switch store.cookingState {
            case .deviceOffline:
                DeviceOfflineView()
            case .noEggsDetected:
                NoEggsView()
            case .wifiLost(let remaining):
                WifiLostView(remainingSeconds: remaining)
            case .active:
                CookingActiveView()
            case .complete(let session):
                CookingCompleteView(session: session)
            case .idle:
                MainCookView()
            }
        }
    }
}
