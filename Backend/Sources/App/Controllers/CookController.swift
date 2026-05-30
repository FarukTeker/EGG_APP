import Vapor
import Fluent

// MARK: - UC-06, UC-07, UC-11, UC-14: Cook Sessions + History

struct CookController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let cook = routes.grouped("cook")

        // Sessions (history) — UC-14
        let sessions = cook.grouped("sessions")
        sessions.get(use: history)
        sessions.post(use: startCook)
        sessions.patch(":sessionID", use: updateSession)
        sessions.delete("history", use: clearHistory)
    }

    // GET /api/v1/cook/sessions  — cooking history UC-14
    func history(req: Request) async throws -> [CookSessionResponse] {
        let userID = try req.currentUserID
        return try await CookSession.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$startedAt, .descending)
            .all()
            .map { makeResponse($0) }
    }

    // POST /api/v1/cook/sessions  — start cook UC-06, UC-07
    func startCook(req: Request) async throws -> CookSessionResponse {
        let userID = try req.currentUserID
        let body   = try req.content.decode(StartCookRequest.self)
        try body.validate()

        // Cancel any existing active session for this user
        try await CookSession.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$status == "active")
            .set(\.$status, to: "cancelled")
            .set(\.$completedAt, to: Date())
            .update()

        let session = CookSession(
            userID: userID,
            deviceID: body.deviceId,
            presetName: body.presetName,
            mode: body.mode,
            selectedSections: body.selectedSections,
            donenessLevels: body.donenessLevels
        )
        try await session.save(on: req.db)
        return makeResponse(session)
    }

    // PATCH /api/v1/cook/sessions/:sessionID  — complete or cancel UC-11
    func updateSession(req: Request) async throws -> CookSessionResponse {
        let userID = try req.currentUserID
        guard let sessionID = req.parameters.get("sessionID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let session = try await CookSession.query(on: req.db)
            .filter(\.$id == sessionID)
            .filter(\.$user.$id == userID)
            .first()
        else { throw Abort(.notFound) }

        let body = try req.content.decode(UpdateSessionRequest.self)
        guard ["completed", "cancelled"].contains(body.status) else {
            throw Abort(.badRequest, reason: "status must be 'completed' or 'cancelled'.")
        }
        guard session.status == "active" else {
            throw Abort(.conflict, reason: "Session is already \(session.status).")
        }
        session.status      = body.status
        session.completedAt = Date()
        try await session.save(on: req.db)
        return makeResponse(session)
    }

    // DELETE /api/v1/cook/sessions/history  — clear history UC-14
    func clearHistory(req: Request) async throws -> HTTPStatus {
        let userID = try req.currentUserID
        try await CookSession.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$status != "active")
            .delete()
        return .noContent
    }

    private func makeResponse(_ s: CookSession) -> CookSessionResponse {
        CookSessionResponse(
            id:               s.id ?? UUID(),
            presetName:       s.presetName,
            mode:             s.mode,
            selectedSections: s.selectedSections,
            donenessLevels:   s.donenessLevels,
            status:           s.status,
            startedAt:        s.startedAt,
            completedAt:      s.completedAt
        )
    }
}

// MARK: - UC-17: Notification Preferences

struct NotificationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let notif = routes.grouped("notifications", "preferences")
        notif.get(use: getPrefs)
        notif.put(use: updatePrefs)
    }

    // GET /api/v1/notifications/preferences
    func getPrefs(req: Request) async throws -> NotificationPrefsResponse {
        let userID = try req.currentUserID
        if let prefs = try await NotificationPrefs.query(on: req.db)
            .filter(\.$user.$id == userID).first() {
            return makeResponse(prefs)
        }
        // Create defaults if missing
        let prefs = NotificationPrefs(userID: userID)
        try await prefs.save(on: req.db)
        return makeResponse(prefs)
    }

    // PUT /api/v1/notifications/preferences
    func updatePrefs(req: Request) async throws -> NotificationPrefsResponse {
        let userID = try req.currentUserID
        let body   = try req.content.decode(UpdateNotificationPrefsRequest.self)

        let prefs: NotificationPrefs
        if let existing = try await NotificationPrefs.query(on: req.db)
            .filter(\.$user.$id == userID).first() {
            prefs = existing
        } else {
            prefs = NotificationPrefs(userID: userID)
        }

        if let v = body.cookComplete    { prefs.cookComplete    = v }
        if let v = body.fiveMinReminder { prefs.fiveMinReminder = v }
        if let v = body.scheduledStart  { prefs.scheduledStart  = v }
        if let v = body.offlineAlert    { prefs.offlineAlert    = v }
        if let v = body.firmwareUpdates { prefs.firmwareUpdates = v }
        if let v = body.tipsRecipes     { prefs.tipsRecipes     = v }
        if let v = body.vestelMarketing { prefs.vestelMarketing = v }
        try await prefs.save(on: req.db)
        return makeResponse(prefs)
    }

    private func makeResponse(_ p: NotificationPrefs) -> NotificationPrefsResponse {
        NotificationPrefsResponse(
            cookComplete:    p.cookComplete,
            fiveMinReminder: p.fiveMinReminder,
            scheduledStart:  p.scheduledStart,
            offlineAlert:    p.offlineAlert,
            firmwareUpdates: p.firmwareUpdates,
            tipsRecipes:     p.tipsRecipes,
            vestelMarketing: p.vestelMarketing
        )
    }
}
