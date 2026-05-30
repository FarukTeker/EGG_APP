import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {

    // MARK: - Navigation state (UC-01..UC-05)
    @Published var hasCompletedOnboarding: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var hasPairedDevice: Bool = false

    // MARK: - User
    @Published var currentUser: VestelUser = VestelUser(firstName: "Ahmet", lastName: "Yılmaz", email: "ahmet@vestel.com")
    @Published var notificationPrefs = NotificationPrefs()
    @Published var language: AppLanguage = .english
    @Published var notificationsGranted: Bool = false

    // MARK: - Devices (UC-05, UC-15)
    @Published var devices: [EggDevice] = []
    @Published var activeDevice: EggDevice?

    // MARK: - Cooking (UC-06..UC-11)
    @Published var cookMode: CookMode = .bulk
    @Published var selectedSections: Set<Int> = [0, 1, 2]
    @Published var donenessLevels: [String] = ["Medium", "Medium", "Medium"]
    @Published var cookingState: CookingState = .idle
    private var cookTimer: Timer?
    private var remainingSeconds: Int = 0
    private var totalSeconds: Int = 0

    // MARK: - Presets (UC-09, UC-12, UC-13)
    @Published var presets: [EggPreset] = []

    // MARK: - History (UC-14)
    @Published var history: [HistoryEntry] = []

    init() {
        seedDemoData()
    }

    // MARK: - Auth (UC-02, UC-03)

    func login(email: String, password: String) -> Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        currentUser.email = email
        isAuthenticated = true
        return true
    }

    func register(firstName: String, lastName: String, email: String, password: String) -> Bool {
        guard !email.isEmpty, password.count >= 8 else { return false }
        currentUser = VestelUser(firstName: firstName, lastName: lastName, email: email)
        isAuthenticated = true
        return true
    }

    func logout() {
        isAuthenticated = false
        hasPairedDevice = false
        activeDevice = nil
    }

    // MARK: - Pairing (UC-05)

    func pairDevice(_ device: EggDevice) {
        devices.append(device)
        activeDevice = device
        hasPairedDevice = true
    }

    func setActiveDevice(_ device: EggDevice) {
        activeDevice = device
    }

    // MARK: - Cook flow (UC-06..UC-11)

    func startCook(presetName: String? = nil) {
        guard activeDevice != nil else { cookingState = .deviceOffline; return }
        guard !selectedSections.isEmpty else { cookingState = .noEggsDetected; return }

        let baseSeconds = donenessSeconds()
        totalSeconds = baseSeconds
        remainingSeconds = baseSeconds
        cookingState = .active(remainingSeconds: remainingSeconds, totalSeconds: totalSeconds)

        cookTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickCookTimer()
            }
        }
    }

    func cancelCook() {
        cookTimer?.invalidate()
        cookTimer = nil

        let session = CookSession(
            mode: cookMode,
            selectedSections: Array(selectedSections).sorted(),
            donenessLevels: donenessLevels,
            startedAt: Date().addingTimeInterval(-Double(totalSeconds - remainingSeconds)),
            cancelled: true
        )
        if let device = activeDevice {
            history.insert(HistoryEntry(session: session, deviceName: device.name), at: 0)
        }
        cookingState = .idle
    }

    func cookAgain() {
        cookingState = .idle
    }

    func saveAsPreset(name: String) {
        let preset = EggPreset(
            name: name,
            mode: cookMode,
            selectedSections: Array(selectedSections).sorted(),
            donenessLevels: donenessLevels
        )
        presets.insert(preset, at: 0)
        cookingState = .idle
    }

    private func tickCookTimer() {
        guard remainingSeconds > 0 else {
            cookTimer?.invalidate()
            cookTimer = nil
            let session = CookSession(
                mode: cookMode,
                selectedSections: Array(selectedSections).sorted(),
                donenessLevels: donenessLevels,
                startedAt: Date().addingTimeInterval(-Double(totalSeconds)),
                completedAt: Date()
            )
            if let device = activeDevice {
                history.insert(HistoryEntry(session: session, deviceName: device.name), at: 0)
            }
            cookingState = .complete(session: session)
            return
        }
        remainingSeconds -= 1
        cookingState = .active(remainingSeconds: remainingSeconds, totalSeconds: totalSeconds)
    }

    private func donenessSeconds() -> Int {
        let levels = cookMode == .bulk ? [donenessLevels[0]] : donenessLevels.filter { !$0.isEmpty }
        let maxLevel = levels.max { a, b in donenessOrder(a) < donenessOrder(b) } ?? "Medium"
        switch maxLevel {
        case "Soft":   return 4 * 60
        case "Medium": return 6 * 60
        case "Hard":   return 9 * 60
        default:       return 6 * 60
        }
    }

    private func donenessOrder(_ level: String) -> Int {
        switch level { case "Soft": return 1; case "Medium": return 2; case "Hard": return 3; default: return 0 }
    }

    // MARK: - Presets (UC-09, UC-12, UC-13)

    func applyPreset(_ preset: EggPreset) {
        cookMode = preset.mode
        selectedSections = Set(preset.selectedSections)
        donenessLevels = preset.donenessLevels
    }

    func savePreset(_ preset: EggPreset) {
        if let i = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[i] = preset
        } else {
            presets.insert(preset, at: 0)
        }
    }

    func deletePreset(_ preset: EggPreset) {
        presets.removeAll { $0.id == preset.id }
    }

    // MARK: - Demo seed data

    private func seedDemoData() {
        devices = [
            EggDevice(name: "Kitchen Cooker", modelCode: "VS-EG-2025", state: .active),
            EggDevice(name: "Office Cooker",  modelCode: "VS-EG-2024", state: .idle),
            EggDevice(name: "Summer House",   modelCode: "VS-EG-2024", state: .offline,
                      lastSeenAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()))
        ]
        activeDevice = devices.first

        presets = [
            EggPreset(name: "Morning Routine",    mode: .separate, selectedSections: [0,1], donenessLevels: ["Soft","Medium","Hard"]),
            EggPreset(name: "Sunday Brunch",      mode: .bulk,     selectedSections: [0,1,2], donenessLevels: ["Medium","Medium","Medium"]),
            EggPreset(name: "Grandma's Favourite", mode: .separate, selectedSections: [0,1,2], donenessLevels: ["Soft","Medium","Hard"]),
            EggPreset(name: "Kid's Breakfast",    mode: .bulk,     selectedSections: [0,1], donenessLevels: ["Soft","Soft","Soft"])
        ]

        let base = Date()
        func d(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }

        history = [
            HistoryEntry(session: CookSession(presetName: "Sunday Brunch",      mode: .bulk,     selectedSections:[0,1,2], donenessLevels:["Medium","Medium","Medium"], startedAt: d(0)),  deviceName: "Kitchen Cooker"),
            HistoryEntry(session: CookSession(presetName: "Quick boil",          mode: .bulk,     selectedSections:[0],     donenessLevels:["Soft","",""],               startedAt: d(-1)), deviceName: "Kitchen Cooker"),
            HistoryEntry(session: CookSession(presetName: "Cancelled cook",      mode: .bulk,     selectedSections:[1],     donenessLevels:["Medium","",""],             startedAt: d(-2), cancelled: true), deviceName: "Kitchen Cooker"),
            HistoryEntry(session: CookSession(presetName: "Grandma's Favourite", mode: .separate, selectedSections:[0,1,2], donenessLevels:["Soft","Medium","Hard"],    startedAt: d(-3)), deviceName: "Kitchen Cooker"),
            HistoryEntry(session: CookSession(presetName: "Morning Routine",     mode: .bulk,     selectedSections:[0,1],   donenessLevels:["Hard","Hard",""],           startedAt: d(-7)), deviceName: "Kitchen Cooker")
        ]

        hasPairedDevice = true
    }
}
