import Fluent
import Vapor
import JWT

// MARK: - User Model (UC-02, UC-03, UC-16)

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id) var id: UUID?
    @Field(key: "first_name")   var firstName: String
    @Field(key: "last_name")    var lastName: String
    @Field(key: "email")        var email: String
    @Field(key: "password_hash") var passwordHash: String
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    @Children(for: \.$user) var devices: [Device]
    @Children(for: \.$user) var presets: [Preset]
    @Children(for: \.$user) var cookSessions: [CookSession]
    @OptionalChild(for: \.$user) var notificationPrefs: NotificationPrefs?

    init() {}

    init(id: UUID? = nil, firstName: String, lastName: String,
         email: String, passwordHash: String) {
        self.id           = id
        self.firstName    = firstName
        self.lastName     = lastName
        self.email        = email
        self.passwordHash = passwordHash
    }

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

// MARK: - JWT Payload

struct UserPayload: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var userID: UUID

    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
