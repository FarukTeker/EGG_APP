import Fluent
import Vapor

// MARK: - Watch S20: Watch-specific settings (Haptics, Chime, Auto-start)

final class WatchSettings: Model, Content, @unchecked Sendable {
    static let schema = "watch_settings"

    @ID(key: .id)  var id: UUID?
    @Parent(key: "user_id")     var user: User
    @Field(key: "haptics")      var haptics: Bool
    @Field(key: "chime")        var chime: Bool
    @Field(key: "auto_start")   var autoStart: Bool

    init() {}

    init(userID: UUID) {
        self.$user.id  = userID
        self.haptics   = true
        self.chime     = true
        self.autoStart = false
    }
}
