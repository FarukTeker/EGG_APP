import Vapor
import Fluent

// MARK: - UC-06, UC-07, UC-10, UC-11, UC-14: Cook Sessions + History

struct CookController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let cook = routes.grouped("cook")
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

    // POST /api/v1/cook/sessions  — start or schedule a cook (UC-06, UC-07, UC-10)
    func startCook(req: Request) async throws -> CookSessionResponse {
        let userID = try req.currentUserID
        let body   = try req.content.decode(StartCookRequest.self)
        try body.validate()

        let isScheduled = body.scheduledAt.map { $0 > Date() } ?? false

        // Only cancel existing active sessions when starting immediately
        if !isScheduled {
            try await CookSession.query(on: req.db)
                .filter(\.$user.$id == userID)
                .filter(\.$status ~~ ["active", "preheating", "paused"])
                .set(\.$status, to: "cancelled")
                .set(\.$completedAt, to: Date())
                .update()
        }

        let session = CookSession(
            userID:           userID,
            deviceID:         body.deviceId,
            presetName:       body.presetName,
            mode:             body.mode,
            selectedSections: body.selectedSections,
            donenessLevels:   body.donenessLevels,
            scheduledAt:      body.scheduledAt
        )
        try await session.save(on: req.db)
        return makeResponse(session)
    }

    // PATCH /api/v1/cook/sessions/:sessionID  — status transitions (UC-11 + Watch S13/S14/S15)
    // Allowed transitions:
    //   scheduled  → preheating | cancelled
    //   preheating → active | cancelled
    //   active     → paused | completed | cancelled
    //   paused     → resumed (→ active) | cancelled
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
        try body.validate()

        switch body.status {

        case "preheating":
            // Watch S13: water is heating — transition from scheduled or active
            guard ["scheduled", "active"].contains(session.status) else {
                throw Abort(.conflict, reason: "Session is \(session.status), cannot enter preheating.")
            }
            session.status = "preheating"

        case "active":
            // Watch S13→S14: preheating done, cooking begins
            guard ["preheating", "scheduled"].contains(session.status) else {
                throw Abort(.conflict, reason: "Session is \(session.status), cannot activate.")
            }
            session.status = "active"

        case "paused":
            // Watch S15: user tapped pause
            guard session.status == "active" else {
                throw Abort(.conflict, reason: "Only active sessions can be paused.")
            }
            session.status   = "paused"
            session.pausedAt = Date()

        case "resumed":
            // Watch S15 → S14: user tapped resume
            guard session.status == "paused" else {
                throw Abort(.conflict, reason: "Only paused sessions can be resumed.")
            }
            session.status   = "active"
            session.pausedAt = nil

        case "completed":
            guard ["active", "paused", "preheating"].contains(session.status) else {
                throw Abort(.conflict, reason: "Session is already \(session.status).")
            }
            session.status      = "completed"
            session.completedAt = Date()

        case "cancelled":
            guard !["completed", "cancelled"].contains(session.status) else {
                throw Abort(.conflict, reason: "Session is already \(session.status).")
            }
            session.status      = "cancelled"
            session.completedAt = Date()

        default:
            throw Abort(.badRequest)
        }

        try await session.save(on: req.db)
        return makeResponse(session)
    }

    // DELETE /api/v1/cook/sessions/history  — clear history UC-14
    func clearHistory(req: Request) async throws -> HTTPStatus {
        let userID = try req.currentUserID
        try await CookSession.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$status !~ ["active", "preheating", "paused", "scheduled"])
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
            scheduledAt:      s.scheduledAt,
            pausedAt:         s.pausedAt,
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
