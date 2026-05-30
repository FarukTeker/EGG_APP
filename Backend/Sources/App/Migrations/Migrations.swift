import Fluent

// MARK: - UC-02: Users table

struct CreateUsers: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("users")
            .id()
            .field("first_name",    .string,   .required)
            .field("last_name",     .string,   .required)
            .field("email",         .string,   .required)
            .unique(on: "email")
            .field("password_hash", .string,   .required)
            .field("created_at",    .datetime)
            .create()
    }
    func revert(on db: Database) async throws {
        try await db.schema("users").delete()
    }
}

// MARK: - UC-05: Devices table

struct CreateDevices: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("devices")
            .id()
            .field("user_id",      .uuid,   .required, .references("users", "id", onDelete: .cascade))
            .field("name",         .string, .required)
            .field("model_code",   .string, .required)
            .field("state",        .string, .required)
            .field("is_active",    .bool,   .required)
            .field("created_at",   .datetime)
            .field("last_seen_at", .datetime)
            .create()
    }
    func revert(on db: Database) async throws {
        try await db.schema("devices").delete()
    }
}

// MARK: - UC-09, UC-12: Presets table

struct CreatePresets: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("presets")
            .id()
            .field("user_id",          .uuid,   .required, .references("users", "id", onDelete: .cascade))
            .field("name",             .string, .required)
            .field("mode",             .string, .required)
            .field("selected_sections", .array(of: .int), .required)
            .field("doneness_levels",   .array(of: .string), .required)
            .field("created_at",       .datetime)
            .field("updated_at",       .datetime)
            .create()
    }
    func revert(on db: Database) async throws {
        try await db.schema("presets").delete()
    }
}

// MARK: - UC-06, UC-11: Cook Sessions table

struct CreateCookSessions: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("cook_sessions")
            .id()
            .field("user_id",          .uuid,   .required, .references("users", "id", onDelete: .cascade))
            .field("device_id",        .uuid)
            .field("preset_name",      .string)
            .field("mode",             .string, .required)
            .field("selected_sections", .array(of: .int), .required)
            .field("doneness_levels",   .array(of: .string), .required)
            .field("status",           .string, .required)
            .field("started_at",       .datetime)
            .field("completed_at",     .datetime)
            .create()
    }
    func revert(on db: Database) async throws {
        try await db.schema("cook_sessions").delete()
    }
}

// MARK: - UC-17: Notification prefs table

struct CreateNotificationPrefs: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("notification_prefs")
            .id()
            .field("user_id",          .uuid, .required, .references("users", "id", onDelete: .cascade))
            .unique(on: "user_id")
            .field("cook_complete",    .bool, .required)
            .field("five_min_reminder",.bool, .required)
            .field("scheduled_start",  .bool, .required)
            .field("offline_alert",    .bool, .required)
            .field("firmware_updates", .bool, .required)
            .field("tips_recipes",     .bool, .required)
            .field("vestel_marketing", .bool, .required)
            .create()
    }
    func revert(on db: Database) async throws {
        try await db.schema("notification_prefs").delete()
    }
}
