import SwiftUI
import PhotosUI

// MARK: - UC-13, UC-16, UC-17, UC-18: Settings

struct SettingsTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var route: SettingsRoute? = nil
    var onClose: (() -> Void)? = nil

    enum SettingsRoute: Hashable {
        case profile, changePassword, devices, defaultStyle, notifications, language, help
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

                        VListRow(label: "Devices", value: "\(store.devices.count)", showChev: true) { route = .devices }
                        VListRow(label: "Default style", value: store.defaultStyle, showChev: true) { route = .defaultStyle }
                        VListRow(label: "Auto-detect eggs", toggle: $store.autoDetectEggs)

                        // App section
                        Text("App")
                            .font(.vestelCaption).foregroundStyle(Color.fg3)
                            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 8)

                        VListRow(label: "Notifications", showChev: true) { route = .notifications }
                        VListRow(label: "Language", value: store.language.rawValue.components(separatedBy: " ").first ?? "EN", showChev: true) { route = .language }
                        VListRow(label: "Dark Mode", toggle: $store.isDarkMode)
                        VListRow(label: "Help", showChev: true) { route = .help }

                        // Sign out
                        Button { store.logout() } label: {
                            Text("Sign Out")
                                .font(.vestelButton)
                                .foregroundStyle(Color.brandYellow)
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
                if let onClose {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: onClose) {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(Color.fg1)
                        }
                    }
                }
            }
            .navigationDestination(item: $route) { r in
                switch r {
                case .profile:        EditProfileView()
                case .changePassword: ChangePasswordView()
                case .devices:        DevicesManagementView()
                case .defaultStyle:   DefaultStyleView()
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
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var avatarImage: Image? = nil

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Profile", onBack: { dismiss() })

                VStack(spacing: 12) {
                    // Avatar — tapping opens the photo picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        ZStack {
                            Circle()
                                .fill(Color.bgSurface2)
                                .frame(width: 80, height: 80)
                            if let img = avatarImage {
                                img
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.fg2)
                            }
                            // Camera badge
                            Circle()
                                .fill(Color.accentOrange)
                                .frame(width: 26, height: 26)
                                .overlay(Image(systemName: "camera.fill").font(.system(size: 12)).foregroundStyle(.white))
                                .offset(x: 28, y: 28)
                        }
                    }
                    .padding(.top, 24)
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImg = UIImage(data: data) {
                                avatarImage = Image(uiImage: uiImg)
                            }
                        }
                    }

                    Text("Change photo")
                        .font(.vestelLabel)
                        .foregroundStyle(Color.accentOrange)
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

// MARK: - Profile Overview (shown from the home topbar avatar)

struct ProfileOverviewView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showDefaultStyle = false
    @State private var showPresetEditor = false
    @State private var editingPreset: EggPreset? = nil
    @State private var showScheduleEditor = false

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Profile", onBack: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        HStack {
                            Button { showEditProfile = true } label: {
                                Circle()
                                    .fill(Color.accentOrange)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(.white)
                                    )
                            }
                            Spacer()
                            Button { showSettings = true } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.fg2)
                                    .frame(width: 36, height: 36)
                                    .background(Color.bgSurface1)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, 8)

                        VStack(alignment: .center, spacing: 0) {
                            Text("Egg Preferences")
                                .font(.vestelH3)
                                .foregroundStyle(Color.fg1)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 12)
                            Divider().background(Color.line1)

                            VListRow(label: "Default Style", value: store.defaultStyle, showChev: true) {
                                showDefaultStyle = true
                            }
                            VListRow(label: "Notify When Done", toggle: $store.notificationPrefs.cookComplete)
                            VListRow(label: "Auto Detect Eggs", toggle: $store.autoDetectEggs)
                        }

                        VStack(alignment: .center, spacing: 16) {
                            VStack(spacing: 0) {
                                Text("Saved Presets")
                                    .font(.vestelH3)
                                    .foregroundStyle(Color.fg1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 12)
                                Divider().background(Color.line1)
                            }

                            VStack(spacing: 12) {
                                ForEach(store.presets) { preset in
                                    Button {
                                        store.applyPreset(preset)
                                        dismiss()
                                    } label: {
                                        Text(preset.name)
                                            .font(.vestelButton)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.brandYellow)
                                            .clipShape(Capsule())
                                    }
                                }

                                Button {
                                    showScheduleEditor = true
                                } label: {
                                    Text("+ Add Schedule")
                                        .font(.vestelButton)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.brandYellow.opacity(0.85))
                                        .clipShape(Capsule())
                                }

                                Button {
                                    editingPreset = nil
                                    showPresetEditor = true
                                } label: {
                                    Text("+ Add Preset")
                                        .font(.vestelButton)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.brandYellow.opacity(0.85))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) { EditProfileView() }
        .sheet(isPresented: $showSettings) { SettingsTabView(onClose: { showSettings = false }) }
        .sheet(isPresented: $showDefaultStyle) { DefaultStyleView() }
        .sheet(isPresented: $showPresetEditor) { PresetEditorView(preset: editingPreset) }
        .sheet(isPresented: $showScheduleEditor) {
            ScheduleEditorSheet(preselectedPreset: store.presets.first) { newSchedule in
                store.addSchedule(newSchedule)
            }
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
                VNavHeader(title: "Change password", onBack: { dismiss() })
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
                VNavHeader(title: "Notifications", onBack: { dismiss() })
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
                VNavHeader(title: "Language", onBack: { dismiss() })
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
                VNavHeader(title: "Help", onBack: { dismiss() })
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

// MARK: - Default Style Picker

struct DefaultStyleView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let options = ["Soft", "Medium", "Hard"]
    let descriptions = ["Runny yolk · 4 min", "Jammy yolk · 6 min", "Fully set · 9 min"]

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Default Style", onBack: { dismiss() })
                Text("Applied when you start a new cook without adjusting levels.")
                    .font(.vestelCaption)
                    .foregroundStyle(Color.fg3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                VStack(spacing: 10) {
                    ForEach(Array(zip(options, descriptions)), id: \.0) { option, desc in
                        let selected = store.defaultStyle == option
                        Button {
                            store.defaultStyle = option
                        } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option).font(.vestelH3).foregroundStyle(Color.fg1)
                                    Text(desc).font(.vestelCaption).foregroundStyle(Color.fg2)
                                }
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brandYellow)
                                }
                            }
                            .padding(16)
                            .background(selected ? Color.brandYellowSoft : Color.bgSurface1)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selected ? Color.brandYellow : Color.clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VBtn(title: "Save") {
                    store.donenessLevels = [store.defaultStyle, store.defaultStyle, store.defaultStyle]
                    dismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Devices Management (Settings nav version)

struct DevicesManagementView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPairing = false

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Devices",
                           onBack: { dismiss() },
                           trailingIcon: "plus",
                           onTrailing: { showPairing = true })

                if store.devices.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash").font(.system(size: 48)).foregroundStyle(Color.fg3)
                        Text("No devices").font(.vestelH3).foregroundStyle(Color.fg1)
                        Text("Pair your egg cooker to get started.")
                            .font(.vestelCaption).foregroundStyle(Color.fg2)
                            .multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                    Spacer()
                    VBtn(title: "Add device") { showPairing = true }
                        .padding(.horizontal, 24).padding(.bottom, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(store.devices) { device in
                                Button { store.setActiveDevice(device) } label: {
                                    HStack {
                                        VDeviceRow(
                                            name: device.name,
                                            subtitle: "\(device.modelCode) · \(device.state.displayText)",
                                            state: device.state.viewState)
                                        Spacer()
                                        if store.activeDevice?.id == device.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.brandYellow)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                }
                                Divider().background(Color.line1).padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPairing) {
            PairingFlowView(onComplete: { showPairing = false },
                            onCancel:  { showPairing = false })
        }
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
