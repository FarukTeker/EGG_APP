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
    @Published var autoDetectEggs: Bool = true
    @Published var defaultStyle: String = "Medium"
    @Published var isDarkMode: Bool = true
    // Accessibility
    @Published var textSize: Double = 0.5
    @Published var flashNotifications: Bool = false
    @Published var animationsEnabled: Bool = true
    // Privacy & Data
    @Published var shareDataWithVestel: Bool = false
    @Published var rememberMe: Bool = true

    // MARK: - Devices (UC-05, UC-15)
    @Published var devices: [EggDevice] = []
    @Published var activeDevice: EggDevice?

    // MARK: - Cooking (UC-06..UC-11)
    @Published var cookMode: CookMode = .bulk
    @Published var selectedEggs: Set<Int> = [0, 1, 2, 3, 4, 5]
    @Published var donenessLevels: [String] = ["Medium", "Medium", "Medium"]
    @Published var waterLevel: Double = 0.72   // 0..1 — tank fill fraction
    @Published var cookingState: CookingState = .idle
    @Published var isPaused: Bool = false
    private var cookTimer: Timer?
    private var remainingSeconds: Int = 0
    private var totalSeconds: Int = 0

    // MARK: - Presets (UC-09, UC-12, UC-13)
    @Published var presets: [EggPreset] = []

    // MARK: - Scheduled Cooks
    @Published var scheduledCooks: [ScheduledCook] = []

    // MARK: - History (UC-14)
    @Published var history: [HistoryEntry] = []

    init() {
        seedDemoData()
    }

    // MARK: - Auth (UC-02, UC-03)

    func login(email: String, password: String) -> Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        // E-mail büyük/küçük harfe duyarsız, şifre duyarlı karşılaştırılır.
        currentUser.email = email.lowercased()
        isAuthenticated = true
        return true
    }

    func register(firstName: String, lastName: String, email: String, password: String) -> Bool {
        guard !email.isEmpty, password.count >= 8 else { return false }
        currentUser = VestelUser(firstName: firstName, lastName: lastName, email: email.lowercased())
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
        guard !selectedEggs.isEmpty else { cookingState = .noEggsDetected; return }

        let baseSeconds = donenessSeconds()
        totalSeconds = baseSeconds
        remainingSeconds = baseSeconds
        isPaused = false
        cookingState = .active(remainingSeconds: remainingSeconds, totalSeconds: totalSeconds)
        startTimer()
    }

    private func startTimer() {
        cookTimer?.invalidate()
        cookTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickCookTimer()
            }
        }
    }

    func pauseCook() {
        guard cookingState.isActive, !isPaused else { return }
        cookTimer?.invalidate()
        cookTimer = nil
        isPaused = true
    }

    func resumeCook() {
        guard isPaused else { return }
        isPaused = false
        startTimer()
    }

    func cancelCook() {
        cookTimer?.invalidate()
        cookTimer = nil
        isPaused = false

        let session = CookSession(
            mode: cookMode,
            selectedEggs: Array(selectedEggs).sorted(),
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
            selectedEggs: Array(selectedEggs).sorted(),
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
                selectedEggs: Array(selectedEggs).sorted(),
                donenessLevels: donenessLevels,
                startedAt: Date().addingTimeInterval(-Double(totalSeconds)),
                completedAt: Date()
            )
            if let device = activeDevice {
                history.insert(HistoryEntry(session: session, deviceName: device.name), at: 0)
            }
            isPaused = false
            cookingState = .complete(session: session)
            return
        }
        remainingSeconds -= 1
        cookingState = .active(remainingSeconds: remainingSeconds, totalSeconds: totalSeconds)
    }

    private func donenessSeconds() -> Int {
        let activeSections = (0..<3).filter { selectedEggs.contains($0 * 2) || selectedEggs.contains($0 * 2 + 1) }
        let levels = cookMode == .bulk ? [donenessLevels[0]] : activeSections.map { donenessLevels[$0] }
        let maxLevel = levels.max { donenessOrder($0) < donenessOrder($1) } ?? "Medium"
        switch maxLevel {
        case "Soft":   return 4 * 60
        case "Rare":   return 5 * 60
        case "Medium": return 6 * 60
        case "Hard":   return 9 * 60
        default:       return 6 * 60
        }
    }

    private func donenessOrder(_ level: String) -> Int {
        switch level { case "Soft": return 1; case "Rare": return 2; case "Medium": return 3; case "Hard": return 4; default: return 0 }
    }

    // MARK: - Scheduled Cooks

    func addSchedule(_ s: ScheduledCook) { scheduledCooks.insert(s, at: 0) }

    /// Schedules the current compartment selection + doneness as a one-time cook at the next
    /// occurrence of the chosen time-of-day — always within the next 24 hours (no long-term repeat).
    /// Returns the resolved fire date so the UI can confirm "today 7:30 AM" / "tomorrow 6:15 AM".
    @discardableResult
    func scheduleWithin24h(at time: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: time)
        let fire = cal.nextDate(after: Date(), matching: comps, matchingPolicy: .nextTime) ?? Date()
        let preset = EggPreset(name: "Scheduled cook",
                               mode: cookMode,
                               selectedEggs: Array(selectedEggs).sorted(),
                               donenessLevels: donenessLevels)
        addSchedule(ScheduledCook(preset: preset,
                                  scheduleType: .oneTime,
                                  fireTime: fire,
                                  oneTimeDate: fire))
        return fire
    }

    func updateSchedule(_ s: ScheduledCook) {
        if let i = scheduledCooks.firstIndex(where: { $0.id == s.id }) { scheduledCooks[i] = s }
    }

    func deleteSchedule(_ s: ScheduledCook) { scheduledCooks.removeAll { $0.id == s.id } }

    // MARK: - Presets (UC-09, UC-12, UC-13)

    func applyPreset(_ preset: EggPreset) {
        cookMode = preset.mode
        selectedEggs = Set(preset.selectedEggs)
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
            EggPreset(name: "Morning Routine",     mode: .separate, selectedEggs: [0,1,2,3],     donenessLevels: ["Soft","Medium","Hard"]),
            EggPreset(name: "Sunday Brunch",       mode: .bulk,     selectedEggs: [0,1,2,3,4,5], donenessLevels: ["Medium","Medium","Medium"]),
            EggPreset(name: "Grandma's Favourite", mode: .separate, selectedEggs: [0,1,2,3,4,5], donenessLevels: ["Soft","Medium","Hard"]),
            EggPreset(name: "Kid's Breakfast",     mode: .bulk,     selectedEggs: [0,1,2,3],     donenessLevels: ["Soft","Soft","Soft"])
        ]

        let base = Date()
        func d(_ offset: Int) -> Date { Calendar.current.date(byAdding: .day, value: offset, to: base)! }

        history = [
            HistoryEntry(session: CookSession(presetName: "Sunday Brunch",      mode: .bulk,     selectedEggs:[0,1,2,3,4,5], donenessLevels:["Medium","Medium","Medium"], startedAt: d(0)),  deviceName: "Kitchen Cooker"),
            HistoryEntry(session: CookSession(presetName: "Quick boil",         mode: .bulk,     selectedEggs:[0,1],         donenessLevels:["Soft","Medium","Medium"],  startedAt: d(-1)), deviceName: "Kitchen Cooker"),
            HistoryEntry(session: CookSession(presetName: "Cancelled cook",     mode: .bulk,     selectedEggs:[2,3],         donenessLevels:["Medium","Medium","Medium"],startedAt: d(-2), cancelled: true), deviceName: "Kitchen Cooker"),
            HistoryEntry(session: CookSession(presetName: "Grandma's Favourite",mode: .separate, selectedEggs:[0,1,2,3,4,5], donenessLevels:["Soft","Medium","Hard"],   startedAt: d(-3)), deviceName: "Kitchen Cooker"),
            HistoryEntry(session: CookSession(presetName: "Morning Routine",    mode: .bulk,     selectedEggs:[0,1,2,3],     donenessLevels:["Hard","Hard","Medium"],    startedAt: d(-7)), deviceName: "Kitchen Cooker")
        ]

        // Seed a sample weekly schedule
        var morningTime = DateComponents()
        morningTime.hour = 7; morningTime.minute = 30
        if let t = Calendar.current.date(from: morningTime), let p = presets.first {
            scheduledCooks = [
                ScheduledCook(preset: p, scheduleType: .weekly,
                              fireTime: t, weekdays: [2, 4, 6])  // Mon, Wed, Fri
            ]
        }

        hasPairedDevice = true
    }
}
