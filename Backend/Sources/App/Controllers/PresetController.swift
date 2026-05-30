import Vapor
import Fluent

// MARK: - UC-09, UC-12, UC-13: Preset CRUD

struct PresetController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let presets = routes.grouped("presets")
        presets.get(use: list)
        presets.post(use: create)
        presets.put(":presetID", use: update)
        presets.delete(":presetID", use: delete)
    }

    // GET /api/v1/presets
    func list(req: Request) async throws -> [PresetResponse] {
        let userID = try req.currentUserID
        return try await Preset.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$updatedAt, .descending)
            .all()
            .map { makeResponse($0) }
    }

    // POST /api/v1/presets
    func create(req: Request) async throws -> PresetResponse {
        let userID = try req.currentUserID
        let body   = try req.content.decode(CreatePresetRequest.self)
        try body.validate()

        let preset = Preset(userID: userID, name: body.name, mode: body.mode,
                            selectedSections: body.selectedSections,
                            donenessLevels: body.donenessLevels)
        try await preset.save(on: req.db)
        return makeResponse(preset)
    }

    // PUT /api/v1/presets/:presetID
    func update(req: Request) async throws -> PresetResponse {
        let userID = try req.currentUserID
        guard let presetID = req.parameters.get("presetID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let preset = try await Preset.query(on: req.db)
            .filter(\.$id == presetID)
            .filter(\.$user.$id == userID)
            .first()
        else { throw Abort(.notFound) }

        let body = try req.content.decode(CreatePresetRequest.self)
        try body.validate()
        preset.name             = body.name
        preset.mode             = body.mode
        preset.selectedSections = body.selectedSections
        preset.donenessLevels   = body.donenessLevels
        try await preset.save(on: req.db)
        return makeResponse(preset)
    }

    // DELETE /api/v1/presets/:presetID
    func delete(req: Request) async throws -> HTTPStatus {
        let userID = try req.currentUserID
        guard let presetID = req.parameters.get("presetID", as: UUID.self),
              let preset = try await Preset.query(on: req.db)
                .filter(\.$id == presetID)
                .filter(\.$user.$id == userID)
                .first()
        else { throw Abort(.notFound) }

        try await preset.delete(on: req.db)
        return .noContent
    }

    private func makeResponse(_ p: Preset) -> PresetResponse {
        PresetResponse(id: p.id ?? UUID(), name: p.name, mode: p.mode,
                       selectedSections: p.selectedSections,
                       donenessLevels: p.donenessLevels,
                       updatedAt: p.updatedAt)
    }
}
