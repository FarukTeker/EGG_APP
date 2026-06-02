import Fluent
import Vapor

// MARK: - UC-04: Password Reset Token

final class PasswordResetToken: Model, @unchecked Sendable {
    static let schema = "password_reset_tokens"

    @ID(key: .id)  var id: UUID?
    @Parent(key: "user_id")          var user: User
    @Field(key: "token")             var token: String
    @Field(key: "expires_at")        var expiresAt: Date
    @OptionalField(key: "used_at")   var usedAt: Date?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}

    init(userID: UUID) {
        self.$user.id  = userID
        self.token     = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        self.expiresAt = Date().addingTimeInterval(3600) // 1 hour
    }

    var isValid: Bool { usedAt == nil && expiresAt > Date() }
}
