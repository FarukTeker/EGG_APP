import Vapor
import Fluent

// MARK: - Watch S20: Haptics / Chime / Auto-start settings

struct WatchSettingsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let watch = routes.grouped("watch", "settings")
        watch.get(use: get)
        watch.put(use: update)
    }

    // GET /api/v1/watch/settings
    func get(req: Request) async throws -> WatchSettingsResponse {
        let userID = try req.currentUserID
        if let settings = try await WatchSettings.query(on: req.db)
            .filter(\.$user.$id == userID).first() {
            return makeResponse(settings)
        }
        let settings = WatchSettings(userID: userID)
        try await settings.save(on: req.db)
        return makeResponse(settings)
    }

    // PUT /api/v1/watch/settings
    func update(req: Request) async throws -> WatchSettingsResponse {
        let userID = try req.currentUserID
        let body   = try req.content.decode(UpdateWatchSettingsRequest.self)

        let settings: WatchSettings
        if let existing = try await WatchSettings.query(on: req.db)
            .filter(\.$user.$id == userID).first() {
            settings = existing
        } else {
            settings = WatchSettings(userID: userID)
        }

        if let v = body.haptics   { settings.haptics   = v }
        if let v = body.chime     { settings.chime     = v }
        if let v = body.autoStart { settings.autoStart = v }
        try await settings.save(on: req.db)
        return makeResponse(settings)
    }

    private func makeResponse(_ s: WatchSettings) -> WatchSettingsResponse {
        WatchSettingsResponse(haptics: s.haptics, chime: s.chime, autoStart: s.autoStart)
    }
}
