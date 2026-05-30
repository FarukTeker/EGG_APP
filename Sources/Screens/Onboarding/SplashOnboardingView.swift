import SwiftUI

// MARK: - UC-01: Splash Screen

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 8) {
                Text("vestel")
                    .font(.system(size: 40, weight: .bold, design: .default))
                    .foregroundStyle(Color.brandRed)
                    .tracking(-1)
                Text("Smart Egg Cooker")
                    .font(.vestelCaption)
                    .foregroundStyle(Color.fg3)
                    .tracking(2)
            }
        }
    }
}

// MARK: - UC-01: Onboarding Flow

struct OnboardingFlowView: View {
    @EnvironmentObject private var store: AppStore
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "circle.hexagongrid.fill",
                    title: "Cook eggs your way",
                    body: "Soft, medium or hard — your cooker remembers exactly how everyone in the house likes them.",
                    tone: .neutral),
        OnboardPage(icon: "wifi",
                    title: "Schedule from anywhere",
                    body: "Set an alarm-style schedule so breakfast is ready the moment you walk into the kitchen.",
                    tone: .neutral),
        OnboardPage(icon: "bell.fill",
                    title: "Never overcook again",
                    body: "We'll send a notification the moment your eggs hit the perfect doneness.",
                    tone: .warning)
    ]

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    let p = pages[page]
                    VBigIcon(systemName: p.icon, tone: p.tone == .warning ? .warning : .primary)
                        .animation(.easeInOut, value: page)
                    Text(p.title)
                        .font(.vestelH2)
                        .foregroundStyle(Color.fg1)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: page)
                    Text(p.body)
                        .font(.vestelCaption)
                        .foregroundStyle(Color.fg2)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                        .animation(.easeInOut, value: page)
                }

                Spacer()

                VDots(count: pages.count, active: page)
                    .padding(.bottom, 28)

                VStack(spacing: 12) {
                    VBtn(title: page == pages.count - 1 ? "Get started" : "Continue") {
                        if page < pages.count - 1 {
                            withAnimation { page += 1 }
                        } else {
                            store.hasCompletedOnboarding = true
                        }
                    }
                    if page < pages.count - 1 {
                        VLinkBtn(title: "Skip") {
                            store.hasCompletedOnboarding = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

private struct OnboardPage {
    let icon: String
    let title: String
    let body: String
    enum Tone { case neutral, warning }
    let tone: Tone
}

// MARK: - UC-01: Permissions Screen

struct PermissionsView: View {
    @EnvironmentObject private var store: AppStore
    var onAllow: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VTopbar(showAvatar: false)

                Spacer()

                VStack(spacing: 16) {
                    Text("Allow notifications")
                        .font(.vestelH2)
                        .foregroundStyle(Color.fg1)
                        .multilineTextAlignment(.center)
                    Text("So you know the second your eggs are ready.")
                        .font(.vestelCaption)
                        .foregroundStyle(Color.fg2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    VBigIcon(systemName: "bell.fill", tone: .primary)
                }

                Spacer()

                VStack(spacing: 2) {
                    permissionRow("Cooking complete", granted: true)
                    permissionRow("Scheduled cooks", granted: true)
                    permissionRow("Marketing", granted: false)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                VStack(spacing: 12) {
                    VBtn(title: "Allow") {
                        store.notificationsGranted = true
                        onAllow()
                    }
                    VBtn(title: "Maybe later", kind: .ghost) { onSkip() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func permissionRow(_ label: String, granted: Bool) -> some View {
        HStack {
            Text(label).font(.vestelBody).foregroundStyle(Color.fg1)
            Spacer()
            Text(granted ? "✓" : "—")
                .font(.vestelLabel)
                .foregroundStyle(granted ? Color.success : Color.fg3)
        }
        .padding(.vertical, 12)
        .overlay(Divider().background(Color.line1), alignment: .bottom)
    }
}
