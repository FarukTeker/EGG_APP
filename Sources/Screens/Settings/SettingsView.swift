import SwiftUI

// MARK: - UC-13, UC-16, UC-17, UC-18: Settings

struct SettingsTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var route: SettingsRoute? = nil

    enum SettingsRoute: Hashable {
        case profile, changePassword, notifications, language, help
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Account section
                        Text("Account")
                            .font(.vestelCaption).foregroundStyle(Color.fg3)
                            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 8)

                        VListRow(label: "Profile", showChev: true) { route = .profile }
                        VListRow(label: "Change password", showChev: true) { route = .changePassword }

                        // Cooker section
                        Text("Cooker")
                            .font(.vestelCaption).foregroundStyle(Color.fg3)
                            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 8)

                        VListRow(label: "Devices", value: "\(store.devices.count)", showChev: true) { }
                        VListRow(label: "Default style", value: store.donenessLevels[0], showChev: true) { }
                        VListRow(label: "Auto-detect eggs", toggle: $store.notificationsGranted)

                        // App section
                        Text("App")
                            .font(.vestelCaption).foregroundStyle(Color.fg3)
                            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 8)

                        VListRow(label: "Notifications", showChev: true) { route = .notifications }
                        VListRow(label: "Language", value: store.language.rawValue.components(separatedBy: " ").first ?? "EN", showChev: true) { route = .language }
                        VListRow(label: "Help", showChev: true) { route = .help }

                        // Sign out
                        Button {
                            store.logout()
                        } label: {
                            Text("Sign Out")
                                .font(.vestelButton)
                                .foregroundStyle(Color.brandRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings").font(.vestelH3).foregroundStyle(Color.fg1)
                }
            }
            .navigationDestination(item: $route) { r in
                switch r {
                case .profile:        EditProfileView()
                case .changePassword: ChangePasswordView()
                case .notifications:  NotificationSettingsView()
                case .language:       LanguageView()
                case .help:           HelpView()
                }
            }
        }
    }
}

// MARK: - UC-16: Edit Profile

struct EditProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Profile") { dismiss() }

                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.bgSurface2)
                        .frame(width: 64, height: 64)
                        .overlay(Image(systemName: "person").font(.system(size: 28)).foregroundStyle(Color.fg2))
                        .padding(.top, 24)

                    Button { } label: {
                        Text("Change photo").font(.vestelLabel).foregroundStyle(Color.accentOrange)
                    }
                }

                VStack(spacing: 12) {
                    VInput(placeholder: "Name",  text: $firstName)
                    VInput(placeholder: "Last Name", text: $lastName)
                    VInput(placeholder: "Email", text: $email)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                VBtn(title: "Save") {
                    if !firstName.isEmpty { store.currentUser.firstName = firstName }
                    if !lastName.isEmpty  { store.currentUser.lastName  = lastName  }
                    if !email.isEmpty     { store.currentUser.email     = email     }
                    dismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            firstName = store.currentUser.firstName
            lastName  = store.currentUser.lastName
            email     = store.currentUser.email
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Change Password (inline Reset flow)

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var newPass = ""
    @State private var confirm = ""

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Change password") { dismiss() }
                VStack(spacing: 12) {
                    VInput(placeholder: "Current password",  text: $current, isSecure: true)
                    VInput(placeholder: "New password",      text: $newPass, isSecure: true)
                    VInput(placeholder: "Confirm new password", text: $confirm, isSecure: true)
                }
                .padding(.horizontal, 24).padding(.top, 24)
                Text("8+ characters, at least one number.")
                    .font(.vestelCaption).foregroundStyle(Color.fg3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24).padding(.top, 10)
                Spacer()
                VBtn(title: "Update password") { dismiss() }
                    .padding(.horizontal, 24).padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - UC-17: Notification Settings

struct NotificationSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Notifications") { dismiss() }
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionHeader("Cooking")
                        VListRow(label: "Cook complete",    toggle: $store.notificationPrefs.cookComplete)
                        VListRow(label: "5 min reminder",  toggle: $store.notificationPrefs.fiveMinReminder)
                        VListRow(label: "Scheduled start", toggle: $store.notificationPrefs.scheduledStart)
                        sectionHeader("Device")
                        VListRow(label: "Offline alert",    toggle: $store.notificationPrefs.offlineAlert)
                        VListRow(label: "Firmware updates", toggle: $store.notificationPrefs.firmwareUpdates)
                        sectionHeader("News")
                        VListRow(label: "Tips & recipes",   toggle: $store.notificationPrefs.tipsRecipes)
                        VListRow(label: "Vestel marketing", toggle: $store.notificationPrefs.vestelMarketing)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.vestelCaption).foregroundStyle(Color.fg3)
            .padding(.top, 20).padding(.bottom, 8)
    }
}

// MARK: - UC-18: Language Selection

struct LanguageView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Language") { dismiss() }
                List(AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        store.language = lang
                    } label: {
                        HStack {
                            Text(lang.rawValue).font(.vestelBody).foregroundStyle(Color.fg1)
                            Spacer()
                            if store.language == lang {
                                Text("✓").font(.vestelBody).foregroundStyle(Color.success)
                            }
                        }
                    }
                    .listRowBackground(Color.bgApp)
                    .listRowSeparatorTint(Color.line1)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                VBtn(title: "Apply") { dismiss() }
                    .padding(.horizontal, 24).padding(.vertical, 24)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Help (stub)

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Help") { dismiss() }
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle").font(.system(size: 52)).foregroundStyle(Color.fg3)
                    Text("Need help?").font(.vestelH3).foregroundStyle(Color.fg1)
                    Text("Visit vestel.com/support or contact us at eggcooker@vestel.com")
                        .font(.vestelCaption).foregroundStyle(Color.fg2).multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Low Water Warning (UC-22)

struct LowWaterView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            VTopbar()
            Spacer()
            VBigIcon(systemName: "exclamationmark", tone: .warning)
            Text("Refill water tank")
                .font(.vestelH2).foregroundStyle(Color.fg1).padding(.top, 16)
            Text("Your cooker needs at least 100ml of water to start. Add water and tap retry.")
                .font(.vestelCaption).foregroundStyle(Color.fg2)
                .multilineTextAlignment(.center).padding(.horizontal, 40).padding(.top, 10)
            Spacer()
            VBtn(title: "Retry") { store.cookingState = .idle }
                .padding(.horizontal, 24).padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
}
