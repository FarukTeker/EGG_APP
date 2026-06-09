import SwiftUI
import PhotosUI

// MARK: - Settings Main Screen

struct SettingsTabView: View {
    @EnvironmentObject private var store: AppStore
    @State private var route: SettingsRoute? = nil
    var onClose: (() -> Void)? = nil

    enum SettingsRoute: Hashable {
        case account, notifications, device, accessibility, privacyData
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgApp.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Back button (when opened as sheet)
                    if let onClose {
                        HStack {
                            Button(action: onClose) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.brandYellow)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }

                    Text("Settings")
                        .font(.vestelH1)
                        .foregroundStyle(Color.fg1)
                        .padding(.top, onClose != nil ? 12 : 32)
                        .padding(.bottom, 32)

                    VStack(spacing: 12) {
                        settingsButton("Account")    { route = .account }
                        settingsButton("Notifications") { route = .notifications }
                        settingsButton("Device")     { route = .device }
                        settingsButton("Accessibility") { route = .accessibility }
                        settingsButton("Privacy & Data") { route = .privacyData }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    VStack(spacing: 4) {
                        Button("Terms & Conditions") { }
                            .font(.vestelCaption)
                            .foregroundStyle(Color.fg3)
                        Text("App Version 1.0.0")
                            .font(.vestelCaption)
                            .foregroundStyle(Color.fg3)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $route) { r in
                switch r {
                case .account:       AccountSettingsView()
                case .notifications: NotificationSettingsView()
                case .device:        DeviceSettingsView()
                case .accessibility: AccessibilitySettingsView()
                case .privacyData:   PrivacyDataView()
                }
            }
        }
    }

    private func settingsButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.vestelBody)
                .foregroundStyle(Color.fg1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.bgSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showUpdateInfo = false
    @State private var showChangePassword = false
    @State private var showLanguage = false
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Account", onBack: { dismiss() })

                VStack(spacing: 0) {
                    accountRow("Update information") { showUpdateInfo = true }
                    accountRow("Change password")    { showChangePassword = true }
                    accountRow("Storage & Cache")    { }
                    accountRow("Language")           { showLanguage = true }

                    HStack {
                        Text("Share data with Vestel")
                            .font(.vestelBody).foregroundStyle(Color.fg1)
                        Spacer()
                        Toggle("", isOn: $store.shareDataWithVestel)
                            .tint(Color.brandYellow)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    Divider().background(Color.line1).padding(.horizontal, 24)
                }
                .padding(.top, 8)

                Spacer()

                VBtn(title: "Delete Account", kind: .dangerOutline) {
                    showDeleteAlert = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showUpdateInfo)      { EditProfileView() }
        .sheet(isPresented: $showChangePassword)  { ChangePasswordView() }
        .sheet(isPresented: $showLanguage)        { LanguageView() }
        .alert("Delete account?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { store.logout() }
        } message: {
            Text("All your data will be permanently removed.")
        }
    }

    private func accountRow(_ label: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack {
                    Text(label).font(.vestelBody).foregroundStyle(Color.fg1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.fg3)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            Divider().background(Color.line1).padding(.horizontal, 24)
        }
    }
}

// MARK: - UC-17: Notification Settings (Figma)

struct NotificationSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Notifications", onBack: { dismiss() })

                VStack(spacing: 0) {
                    notifRow("Push Notifications",  toggle: $store.notificationPrefs.pushNotifications)
                    notifRow("Cleaning Reminders",  toggle: $store.notificationPrefs.cleaningReminders)
                    notifRow("Promotional Messages", toggle: $store.notificationPrefs.promotionalMessages)
                }
                .padding(.top, 8)

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    private func notifRow(_ label: String, toggle: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label).font(.vestelBody).foregroundStyle(Color.fg1)
                Spacer()
                Toggle("", isOn: toggle)
                    .tint(Color.brandYellow)
                    .labelsHidden()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            Divider().background(Color.line1).padding(.horizontal, 24)
        }
    }
}

// MARK: - Device Settings

struct DeviceSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPairing = false

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Device", onBack: { dismiss() })

                VStack(spacing: 0) {
                    deviceRow("Use History")      { }
                    deviceRow("User Manual")      { }
                    deviceRow("Product Info")     { }
                    deviceRow("Firmware Version") { }
                    deviceRow("Service & Warranty") { }
                }
                .padding(.top, 8)

                Spacer()

                Button { showPairing = true } label: {
                    Text("Scan QR Code")
                        .font(.vestelButton)
                        .foregroundStyle(Color.fg1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.bgSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPairing) {
            PairingFlowView(onComplete: { showPairing = false },
                            onCancel:  { showPairing = false })
        }
    }

    private func deviceRow(_ label: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack {
                    Text(label).font(.vestelBody).foregroundStyle(Color.fg1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.fg3)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            Divider().background(Color.line1).padding(.horizontal, 24)
        }
    }
}

// MARK: - Accessibility Settings (NEW)

struct AccessibilitySettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Accessibility", onBack: { dismiss() })

                VStack(alignment: .leading, spacing: 0) {
                    // Text Size
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Text Size")
                            .font(.vestelBody).foregroundStyle(Color.fg1)
                        HStack(spacing: 10) {
                            Image(systemName: "textformat.size.smaller")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.fg3)
                            Slider(value: $store.textSize, in: 0...1)
                                .tint(Color.brandYellow)
                            Image(systemName: "textformat.size.larger")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.fg3)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    Divider().background(Color.line1).padding(.horizontal, 24)

                    accessibilityRow("Flash Notifications", toggle: $store.flashNotifications)
                    accessibilityRow("Dark Mode",           toggle: $store.isDarkMode)
                    accessibilityRow("Animations",          toggle: $store.animationsEnabled)
                }
                .padding(.top, 8)

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    private func accessibilityRow(_ label: String, toggle: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label).font(.vestelBody).foregroundStyle(Color.fg1)
                Spacer()
                Toggle("", isOn: toggle)
                    .tint(Color.brandYellow)
                    .labelsHidden()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            Divider().background(Color.line1).padding(.horizontal, 24)
        }
    }
}

// MARK: - Privacy & Data (NEW)

struct PrivacyDataView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Privacy & Data", onBack: { dismiss() })

                VStack(spacing: 0) {
                    privacyRow("Share data with Vestel", toggle: $store.shareDataWithVestel)
                    privacyRow("Remember me",            toggle: $store.rememberMe)

                    // App Permissions row
                    VStack(spacing: 0) {
                        Button { } label: {
                            HStack {
                                Text("App Permissions")
                                    .font(.vestelBody).foregroundStyle(Color.fg1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.fg3)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                        }
                        Divider().background(Color.line1).padding(.horizontal, 24)
                    }
                }
                .padding(.top, 8)

                Spacer()

                VBtn(title: "Delete Data", kind: .dangerOutline) {
                    showDeleteAlert = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .alert("Delete all data?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { }
        } message: {
            Text("This will permanently remove all your cooking history and preferences.")
        }
    }

    private func privacyRow(_ label: String, toggle: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label).font(.vestelBody).foregroundStyle(Color.fg1)
                Spacer()
                Toggle("", isOn: toggle)
                    .tint(Color.brandYellow)
                    .labelsHidden()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            Divider().background(Color.line1).padding(.horizontal, 24)
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
                    VInput(placeholder: "Name",      text: $firstName)
                    VInput(placeholder: "Last Name", text: $lastName)
                    VInput(placeholder: "Email",     text: $email)
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
    @State private var showPresetEditor = false
    @State private var editingPreset: EggPreset? = nil
    @State private var showScheduleEditor = false
    @State private var showStylePicker = false

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                // Top bar: avatar left, settings right
                HStack {
                    Button { showEditProfile = true } label: {
                        Circle()
                            .fill(Color.accentOrange)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
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
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Egg Preferences section
                        VStack(spacing: 0) {
                            Text("Egg Preferences")
                                .font(.vestelH3)
                                .foregroundStyle(Color.fg1)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 12)
                            Divider().background(Color.line1)

                            // Default Style with inline picker
                            Button { showStylePicker.toggle() } label: {
                                HStack {
                                    Text("Default Style")
                                        .font(.vestelBody).foregroundStyle(Color.fg1)
                                    Spacer()
                                    Text(store.defaultStyle)
                                        .font(.vestelBody).foregroundStyle(Color.fg3)
                                    Image(systemName: showStylePicker ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12)).foregroundStyle(Color.fg3)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                            }

                            if showStylePicker {
                                VStack(spacing: 0) {
                                    ForEach(["Soft", "Rare", "Medium", "Hard"], id: \.self) { style in
                                        Button {
                                            store.defaultStyle = style
                                            showStylePicker = false
                                        } label: {
                                            HStack {
                                                Text(style)
                                                    .font(.vestelBody)
                                                    .foregroundStyle(store.defaultStyle == style ? Color.brandYellow : Color.fg2)
                                                Spacer()
                                                if store.defaultStyle == style {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundStyle(Color.brandYellow)
                                                }
                                            }
                                            .padding(.horizontal, 32)
                                            .padding(.vertical, 10)
                                            .background(store.defaultStyle == style ? Color.brandYellow.opacity(0.08) : Color.clear)
                                        }
                                    }
                                }
                                .background(Color.bgSurface1)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            Divider().background(Color.line1).padding(.horizontal, 24)

                            VListRow(label: "Notify When Done", toggle: $store.notificationPrefs.cookComplete)
                            VListRow(label: "Auto Detect Eggs", toggle: $store.autoDetectEggs)
                        }

                        // Saved Presets section
                        VStack(spacing: 0) {
                            Text("Saved Presets")
                                .font(.vestelH3)
                                .foregroundStyle(Color.fg1)
                                .frame(maxWidth: .infinity, alignment: .center)
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

                            Button { showScheduleEditor = true } label: {
                                Text("+ Add Schedule")
                                    .font(.vestelButton)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.brandYellow.opacity(0.85))
                                    .clipShape(Capsule())
                            }

                            Button { editingPreset = nil; showPresetEditor = true } label: {
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .animation(.easeInOut(duration: 0.2), value: showStylePicker)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) { EditProfileView() }
        .sheet(isPresented: $showSettings)    { SettingsTabView(onClose: { showSettings = false }) }
        .sheet(isPresented: $showPresetEditor) { PresetEditorView(preset: editingPreset) }
        .sheet(isPresented: $showScheduleEditor) {
            ScheduleEditorSheet(preselectedPreset: store.presets.first) { newSchedule in
                store.addSchedule(newSchedule)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Change Password

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
                    VInput(placeholder: "Current password",     text: $current, isSecure: true)
                    VInput(placeholder: "New password",         text: $newPass,  isSecure: true)
                    VInput(placeholder: "Confirm new password", text: $confirm,  isSecure: true)
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
                    Button { store.language = lang } label: {
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

// MARK: - Default Style Picker

struct DefaultStyleView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let options      = ["Soft", "Rare", "Medium", "Hard"]
    let descriptions = ["Runny yolk · 4 min", "Barely set · 5 min", "Jammy yolk · 6 min", "Fully set · 9 min"]

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            VStack(spacing: 0) {
                VNavHeader(title: "Default Style", onBack: { dismiss() })
                Text("Applied when you start a new cook without adjusting levels.")
                    .font(.vestelCaption).foregroundStyle(Color.fg3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24).padding(.top, 16)

                VStack(spacing: 10) {
                    ForEach(Array(zip(options, descriptions)), id: \.0) { option, desc in
                        let selected = store.defaultStyle == option
                        Button { store.defaultStyle = option } label: {
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
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(selected ? Color.brandYellow : Color.clear, lineWidth: 1.5))
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.top, 20)

                Spacer()

                VBtn(title: "Save") {
                    store.donenessLevels = [store.defaultStyle, store.defaultStyle, store.defaultStyle]
                    dismiss()
                }
                .padding(.horizontal, 24).padding(.bottom, 40)
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
                                    .padding(.horizontal, 24).padding(.vertical, 12)
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
