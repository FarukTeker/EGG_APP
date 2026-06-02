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
    var selectedEggs: [Int]
    var donenessLevels: [String]
    var startedAt: Date
    var completedAt: Date?
    var cancelled: Bool = false

    var eggCount: Int { selectedEggs.count }
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
    var selectedEggs: [Int]
    var donenessLevels: [String]

    var summaryText: String {
        let labels = ["A", "B", "C"]
        let active = (0..<3).filter { selectedEggs.contains($0 * 2) || selectedEggs.contains($0 * 2 + 1) }
        return active.map { "Section \(labels[$0]) · \(donenessLevels[$0])" }.joined(separator: " · ")
    }
}

// MARK: - Scheduled Cook

struct ScheduledCook: Identifiable, Codable {
    var id: UUID = UUID()
    var preset: EggPreset
    var scheduleType: ScheduleType = .oneTime
    var fireTime: Date                  // time-of-day component
    var oneTimeDate: Date? = nil        // date component for one-time
    var weekdays: [Int] = []            // 1=Sun 2=Mon 3=Tue 4=Wed 5=Thu 6=Fri 7=Sat
    var isEnabled: Bool = true

    enum ScheduleType: String, Codable, CaseIterable {
        case oneTime = "One time"
        case weekly  = "Every week"
    }

    var summaryLine: String {
        let t = fireTime.formatted(.dateTime.hour().minute())
        switch scheduleType {
        case .oneTime:
            let d = oneTimeDate?.formatted(.dateTime.day().month(.abbreviated)) ?? "—"
            return "\(d) · \(t)"
        case .weekly:
            let order:  [Int]         = [2,3,4,5,6,7,1]
            let labels: [Int: String] = [2:"Mo",3:"Tu",4:"We",5:"Th",6:"Fr",7:"Sa",1:"Su"]
            let days = order.filter { weekdays.contains($0) }.compactMap { labels[$0] }.joined(separator: " ")
            return days.isEmpty ? "· \(t)" : "\(days) · \(t)"
        }
    }
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
