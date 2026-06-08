import Vapor
import Fluent

// MARK: - UC-09, UC-12, UC-13: Preset CRUD + Share / Import

struct PresetController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let presets = routes.grouped("presets")
        presets.get(use: list)
        presets.post(use: create)
        presets.put(":presetID", use: update)
        presets.delete(":presetID", use: delete)
        presets.get(":presetID", "share", use: share)   // UC-13 generate / fetch share code
        presets.post("import", use: importPreset)        // UC-13 import by code
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

    // GET /api/v1/presets/:presetID/share  — UC-13
    // Returns existing share code or generates a new one.
    // Response includes QR-ready code like "GRNDM-FAV-9132"
    func share(req: Request) async throws -> PresetShareResponse {
        let userID = try req.currentUserID
        guard let presetID = req.parameters.get("presetID", as: UUID.self),
              let preset = try await Preset.query(on: req.db)
                .filter(\.$id == presetID)
                .filter(\.$user.$id == userID)
                .first()
        else { throw Abort(.notFound) }

        if let existing = preset.shareCode {
            return PresetShareResponse(presetId: try preset.requireID(), shareCode: existing)
        }

        let code = generateShareCode(from: preset.name)
        preset.shareCode = code
        try await preset.save(on: req.db)
        return PresetShareResponse(presetId: try preset.requireID(), shareCode: code)
    }

    // POST /api/v1/presets/import  — UC-13 import by share code
    func importPreset(req: Request) async throws -> PresetResponse {
        let userID = try req.currentUserID
        let body   = try req.content.decode(ImportPresetRequest.self)
        let code   = body.code.uppercased().trimmingCharacters(in: .whitespaces)

        guard let original = try await Preset.query(on: req.db)
            .filter(\.$shareCode == code)
            .first()
        else { throw Abort(.notFound, reason: "No preset found with that code.") }

        let copy = Preset(
            userID:           userID,
            name:             original.name + " (imported)",
            mode:             original.mode,
            selectedSections: original.selectedSections,
            donenessLevels:   original.donenessLevels
        )
        try await copy.save(on: req.db)
        return makeResponse(copy)
    }

    // MARK: - Helpers

    // Generates codes in the format "GRNDM-FAV-9132" (wireframe UC-13 example)
    private func generateShareCode(from name: String) -> String {
        let letters = name.uppercased().filter { $0.isLetter || $0.isNumber }
        let a = String(letters.prefix(5)).padding(toLength: 5, withPad: "X", startingAt: 0)
        let b = String(letters.dropFirst(5).prefix(3)).padding(toLength: 3, withPad: "X", startingAt: 0)
        let n = String(format: "%04d", Int.random(in: 1000...9999))
        return "\(a)-\(b)-\(n)"
    }

    private func makeResponse(_ p: Preset) -> PresetResponse {
        PresetResponse(
            id:               p.id ?? UUID(),
            name:             p.name,
            mode:             p.mode,
            selectedSections: p.selectedSections,
            donenessLevels:   p.donenessLevels,
            shareCode:        p.shareCode,
            updatedAt:        p.updatedAt
        )
    }
}
