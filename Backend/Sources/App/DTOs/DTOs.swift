import Vapor

// MARK: - Auth DTOs (UC-02, UC-03, UC-04)

struct RegisterRequest: Content {
    let firstName: String
    let lastName: String
    let email: String
    let password: String

    func validate() throws {
        guard email.contains("@") else { throw Abort(.badRequest, reason: "Invalid email.") }
        guard password.count >= 8 else { throw Abort(.badRequest, reason: "Password must be 8+ characters.") }
        guard !firstName.isEmpty, !lastName.isEmpty else { throw Abort(.badRequest, reason: "Name required.") }
    }
}

struct LoginRequest: Content {
    let email: String
    let password: String
}

struct AuthResponse: Content {
    let token: String
    let userId: UUID
    let email: String
}

struct ChangePasswordRequest: Content {
    let currentPassword: String
    let newPassword: String
}

// UC-04: token-based password reset (email flow)
struct ForgotPasswordRequest: Content {
    let email: String
}

struct ForgotPasswordResponse: Content {
    let message: String
    let resetToken: String  // returned in dev — in prod this would only be emailed
}

struct ResetPasswordRequest: Content {
    let token: String
    let newPassword: String
}

// MARK: - User DTOs (UC-16)

struct UserResponse: Content {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let avatarUrl: String?
    let createdAt: Date?
}

struct UpdateProfileRequest: Content {
    let firstName: String?
    let lastName: String?
    let email: String?
}

struct UploadAvatarRequest: Content {
    let avatarUrl: String   // base64 data URL or remote https URL
}

// MARK: - Device DTOs (UC-05, UC-15)

struct CreateDeviceRequest: Content {
    let name: String
    let modelCode: String
}

// UC-05: QR / manual pairing code flow
struct PairDeviceRequest: Content {
    let pairingCode: String
    let name: String?       // optional friendly name; derived from code if omitted
}

struct DeviceResponse: Content {
    let id: UUID
    let name: String
    let modelCode: String
    let state: String
    let isActive: Bool
    let pairingCode: String?
    let lastSeenAt: Date?
}

// MARK: - Preset DTOs (UC-09, UC-12, UC-13)

struct CreatePresetRequest: Content {
    let name: String
    let mode: String
    let selectedSections: [Int]
    let donenessLevels: [String]

    func validate() throws {
        guard ["bulk", "separate"].contains(mode) else {
            throw Abort(.badRequest, reason: "mode must be 'bulk' or 'separate'.")
        }
        guard !selectedSections.isEmpty else {
            throw Abort(.badRequest, reason: "Select at least one section.")
        }
    }
}

struct PresetResponse: Content {
    let id: UUID
    let name: String
    let mode: String
    let selectedSections: [Int]
    let donenessLevels: [String]
    let shareCode: String?
    let updatedAt: Date?
}

// UC-13: share / import
struct PresetShareResponse: Content {
    let presetId: UUID
    let shareCode: String
}

struct ImportPresetRequest: Content {
    let code: String
}

// MARK: - Cook Session DTOs (UC-06, UC-07, UC-10, UC-11)

struct StartCookRequest: Content {
    let deviceId: UUID?
    let presetName: String?
    let mode: String
    let selectedSections: [Int]
    let donenessLevels: [String]
    let scheduledAt: Date?   // UC-10 scheduled cook — nil means start immediately

    func validate() throws {
        guard ["bulk", "separate"].contains(mode) else {
            throw Abort(.badRequest, reason: "mode must be 'bulk' or 'separate'.")
        }
        guard !selectedSections.isEmpty else {
            throw Abort(.badRequest, reason: "No sections selected.")
        }
    }
}

// UC-11 + Watch S14/S15/S13 status transitions
// Lifecycle: scheduled → preheating → active ⇄ paused → completed | cancelled
struct UpdateSessionRequest: Content {
    let status: String

    func validate() throws {
        let valid = ["preheating", "active", "paused", "resumed", "completed", "cancelled"]
        guard valid.contains(status) else {
            throw Abort(.badRequest, reason: "status must be one of: \(valid.joined(separator: ", ")).")
        }
    }
}

struct CookSessionResponse: Content {
    let id: UUID
    let presetName: String?
    let mode: String
    let selectedSections: [Int]
    let donenessLevels: [String]
    let status: String
    let scheduledAt: Date?
    let pausedAt: Date?
    let startedAt: Date?
    let completedAt: Date?
}

// MARK: - Notification DTOs (UC-17)

struct NotificationPrefsResponse: Content {
    let cookComplete: Bool
    let fiveMinReminder: Bool
    let scheduledStart: Bool
    let offlineAlert: Bool
    let firmwareUpdates: Bool
    let tipsRecipes: Bool
    let vestelMarketing: Bool
}

struct UpdateNotificationPrefsRequest: Content {
    let cookComplete: Bool?
    let fiveMinReminder: Bool?
    let scheduledStart: Bool?
    let offlineAlert: Bool?
    let firmwareUpdates: Bool?
    let tipsRecipes: Bool?
    let vestelMarketing: Bool?
}

// MARK: - Watch Settings DTOs (Watch S20)

struct WatchSettingsResponse: Content {
    let haptics: Bool
    let chime: Bool
    let autoStart: Bool
}

struct UpdateWatchSettingsRequest: Content {
    let haptics: Bool?
    let chime: Bool?
    let autoStart: Bool?
}
