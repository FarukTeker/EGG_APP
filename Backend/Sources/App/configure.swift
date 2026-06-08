import Vapor
import Fluent
import FluentSQLiteDriver
import JWT

public func configure(_ app: Application) async throws {

    // MARK: - Database (SQLite for dev, swap to Postgres for prod)
    let dbPath = app.directory.workingDirectory + "vestel_egg.db"
    app.databases.use(.sqlite(.file(dbPath)), as: .sqlite)

    // MARK: - JWT
    app.jwt.signers.use(.hs256(key: Environment.get("JWT_SECRET") ?? "vestel-egg-secret-dev-2026"))

    // MARK: - Migrations (order matters — tables with FK dependencies come after their parents)
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateDevices())
    app.migrations.add(CreatePresets())
    app.migrations.add(CreateCookSessions())
    app.migrations.add(CreateNotificationPrefs())
    app.migrations.add(CreatePasswordResetTokens())   // UC-04
    app.migrations.add(CreateWatchSettings())         // Watch S20
    try await app.autoMigrate()

    // MARK: - Middleware
    app.middleware.use(CORSMiddleware(configuration: .default()))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    // MARK: - Routes
    try routes(app)
}
