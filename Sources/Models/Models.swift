import Foundation

// MARK: - User

struct VestelUser: Codable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var email: String
    var photoURL: URL? = nil
}

// MARK: - Device

struct EggDevice: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var modelCode: String
    var state: DeviceConnectionState
    var lastSeenAt: Date?
}

enum DeviceConnectionState: String, Codable {
    case active, idle, offline
}

// MARK: - Cook Session

struct CookSession: Identifiable, Codable {
    var id: UUID = UUID()
    var presetName: String?
    var mode: CookMode
    var selectedSections: [Int]
    var donenessLevels: [String]
    var startedAt: Date
    var completedAt: Date?
    var cancelled: Bool = false

    var eggCount: Int { selectedSections.count * 2 }
    var displayTitle: String { presetName ?? "Quick boil" }

    var historyDetail: String {
        let count = "\(eggCount) egg\(eggCount == 1 ? "" : "s")"
        let levels = Set(donenessLevels).sorted().joined(separator: "/").lowercased()
        return "\(count) · \(levels.isEmpty ? "—" : levels)"
    }
}

enum CookMode: String, Codable {
    case bulk, separate
}

// MARK: - Cooking State

enum CookingState {
    case idle
    case active(remainingSeconds: Int, totalSeconds: Int)
    case complete(session: CookSession)
    case wifiLost(remainingSeconds: Int)
    case deviceOffline
    case noEggsDetected

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }
}

// MARK: - Preset

struct EggPreset: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var mode: CookMode
    var selectedSections: [Int]
    var donenessLevels: [String]

    var summaryText: String {
        donenessLevels.enumerated().map { i, d in
            "Section \(["A","B","C"][i]) · \(d)"
        }.joined(separator: " · ")
    }
}

// MARK: - Scheduled Cook

struct ScheduledCook: Identifiable, Codable {
    var id: UUID = UUID()
    var preset: EggPreset
    var date: Date
}

// MARK: - History Entry

struct HistoryEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var session: CookSession
    var deviceName: String

    var formattedDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(session.startedAt) { return "Today \(timeStr)" }
        if cal.isDateInYesterday(session.startedAt) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: session.startedAt)
    }
    private var timeStr: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "H:mm"
        return fmt.string(from: session.startedAt)
    }
}

// MARK: - Notification Preferences

struct NotificationPrefs: Codable {
    var cookComplete: Bool = true
    var fiveMinReminder: Bool = true
    var scheduledStart: Bool = false
    var offlineAlert: Bool = true
    var firmwareUpdates: Bool = true
    var tipsRecipes: Bool = false
    var vestelMarketing: Bool = false
}

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Codable {
    case turkish   = "Türkçe"
    case english   = "English"
    case german    = "Deutsch"
    case french    = "Français"
    case spanish   = "Español"
    case arabic    = "العربية"
}
