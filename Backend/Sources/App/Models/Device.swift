import Fluent
import Vapor

// MARK: - Device Model (UC-05, UC-15)

final class Device: Model, Content, @unchecked Sendable {
    static let schema = "devices"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id")              var user: User
    @Field(key: "name")                  var name: String
    @Field(key: "model_code")            var modelCode: String
    @Field(key: "state")                 var state: String        // "active" | "idle" | "offline"
    @Field(key: "is_active")             var isActive: Bool
    @OptionalField(key: "pairing_code")  var pairingCode: String? // UC-05 QR/manual pairing
    @Timestamp(key: "created_at", on: .create)  var createdAt: Date?
    @Timestamp(key: "last_seen_at", on: .none)  var lastSeenAt: Date?

    init() {}

    init(id: UUID? = nil, userID: UUID, name: String,
         modelCode: String, state: String = "active", pairingCode: String? = nil) {
        self.id          = id
        self.$user.id    = userID
        self.name        = name
        self.modelCode   = modelCode
        self.state       = state
        self.isActive    = (state == "active")
        self.pairingCode = pairingCode
    }
}

// MARK: - Preset Model (UC-09, UC-12, UC-13)

final class Preset: Model, Content, @unchecked Sendable {
    static let schema = "presets"

    @ID(key: .id)  var id: UUID?
    @Parent(key: "user_id")             var user: User
    @Field(key: "name")                 var name: String
    @Field(key: "mode")                 var mode: String          // "bulk" | "separate"
    @Field(key: "selected_sections")    var selectedSections: [Int]
    @Field(key: "doneness_levels")      var donenessLevels: [String]
    @OptionalField(key: "share_code")   var shareCode: String?    // UC-13 preset sharing
    @Timestamp(key: "created_at", on: .create)  var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update)  var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, userID: UUID, name: String, mode: String,
         selectedSections: [Int], donenessLevels: [String]) {
        self.id               = id
        self.$user.id         = userID
        self.name             = name
        self.mode             = mode
        self.selectedSections = selectedSections
        self.donenessLevels   = donenessLevels
    }
}
