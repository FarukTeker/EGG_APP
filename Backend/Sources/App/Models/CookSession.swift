import Fluent
import Vapor

// MARK: - Cook Session Model (UC-06, UC-07, UC-11, UC-14)

final class CookSession: Model, Content, @unchecked Sendable {
    static let schema = "cook_sessions"

    @ID(key: .id)  var id: UUID?
    @Parent(key: "user_id")           var user: User
    @OptionalField(key: "device_id")  var deviceID: UUID?
    @OptionalField(key: "preset_name") var presetName: String?
    @Field(key: "mode")               var mode: String          // "bulk" | "separate"
    @Field(key: "selected_sections")  var selectedSections: [Int]
    @Field(key: "doneness_levels")    var donenessLevels: [String]
    @Field(key: "status")             var status: String        // "active" | "completed" | "cancelled"
    @Timestamp(key: "started_at", on: .create)     var startedAt: Date?
    @OptionalField(key: "completed_at")             var completedAt: Date?

    init() {}

    init(id: UUID? = nil, userID: UUID, deviceID: UUID? = nil,
         presetName: String? = nil, mode: String,
         selectedSections: [Int], donenessLevels: [String]) {
        self.id               = id
        self.$user.id         = userID
        self.deviceID         = deviceID
        self.presetName       = presetName
        self.mode             = mode
        self.selectedSections = selectedSections
        self.donenessLevels   = donenessLevels
        self.status           = "active"
    }
}

// MARK: - Notification Preferences Model (UC-17)

final class NotificationPrefs: Model, Content, @unchecked Sendable {
    static let schema = "notification_prefs"

    @ID(key: .id)  var id: UUID?
    @Parent(key: "user_id")               var user: User
    @Field(key: "cook_complete")          var cookComplete: Bool
    @Field(key: "five_min_reminder")      var fiveMinReminder: Bool
    @Field(key: "scheduled_start")        var scheduledStart: Bool
    @Field(key: "offline_alert")          var offlineAlert: Bool
    @Field(key: "firmware_updates")       var firmwareUpdates: Bool
    @Field(key: "tips_recipes")           var tipsRecipes: Bool
    @Field(key: "vestel_marketing")       var vestelMarketing: Bool

    init() {}

    init(userID: UUID) {
        self.$user.id      = userID
        self.cookComplete  = true
        self.fiveMinReminder = true
        self.scheduledStart  = false
        self.offlineAlert    = true
        self.firmwareUpdates = true
        self.tipsRecipes     = false
        self.vestelMarketing = false
    }
}
