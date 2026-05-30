import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()

            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !store.hasCompletedOnboarding {
                OnboardingFlowView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else if !store.isAuthenticated {
                AuthFlowView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else if !store.hasPairedDevice {
                EmptyDevicesView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else {
                MainTabView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .animation(.easeInOut(duration: 0.35), value: store.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: store.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: store.hasPairedDevice)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showSplash = false }
            }
        }
    }
}
