import Vapor
import Fluent

// MARK: - UC-05, UC-15: Device CRUD + Pairing

struct DeviceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let devices = routes.grouped("devices")
        devices.get(use: list)
        devices.post(use: create)
        devices.post("pair", use: pair)                          // UC-05 QR / manual code
        devices.delete(":deviceID", use: delete)
        devices.patch(":deviceID", "ping", use: ping)
    }

    // GET /api/v1/devices
    func list(req: Request) async throws -> [DeviceResponse] {
        let userID = try req.currentUserID
        return try await Device.query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()
            .map { makeResponse($0) }
    }

    // POST /api/v1/devices  — manual add (name + modelCode)
    func create(req: Request) async throws -> DeviceResponse {
        let userID = try req.currentUserID
        let body   = try req.content.decode(CreateDeviceRequest.self)
        guard !body.name.isEmpty else { throw Abort(.badRequest, reason: "Device name required.") }

        try await markOthersIdle(userID: userID, db: req.db)
        let device = Device(userID: userID, name: body.name, modelCode: body.modelCode)
        try await device.save(on: req.db)
        return makeResponse(device)
    }

    // POST /api/v1/devices/pair  — UC-05 QR scan / manual pairing code
    // pairingCode format: "VS-EG-2025" (printed on device or shown as QR)
    func pair(req: Request) async throws -> DeviceResponse {
        let userID = try req.currentUserID
        let body   = try req.content.decode(PairDeviceRequest.self)
        guard !body.pairingCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw Abort(.badRequest, reason: "Pairing code required.")
        }

        // Derive a friendly name from the code if not provided
        // e.g. "VS-EG-2025" → "Egg Cooker VS-EG-2025"
        let code = body.pairingCode.uppercased()
        let name = body.name ?? "Egg Cooker \(code)"

        try await markOthersIdle(userID: userID, db: req.db)
        let device = Device(userID: userID, name: name, modelCode: code, pairingCode: code)
        try await device.save(on: req.db)
        return makeResponse(device)
    }

    // DELETE /api/v1/devices/:deviceID
    func delete(req: Request) async throws -> HTTPStatus {
        let userID = try req.currentUserID
        guard let deviceID = req.parameters.get("deviceID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let device = try await Device.query(on: req.db)
            .filter(\.$id == deviceID)
            .filter(\.$user.$id == userID)
            .first()
        else { throw Abort(.notFound) }

        try await device.delete(on: req.db)
        return .noContent
    }

    // PATCH /api/v1/devices/:deviceID/ping  — heartbeat, marks device active
    func ping(req: Request) async throws -> HTTPStatus {
        let userID = try req.currentUserID
        guard let deviceID = req.parameters.get("deviceID", as: UUID.self),
              let device = try await Device.query(on: req.db)
                .filter(\.$id == deviceID)
                .filter(\.$user.$id == userID)
                .first()
        else { throw Abort(.notFound) }

        device.lastSeenAt = Date()
        device.state      = "active"
        device.isActive   = true
        try await device.save(on: req.db)
        return .ok
    }

    // MARK: - Helpers

    private func markOthersIdle(userID: UUID, db: Database) async throws {
        try await Device.query(on: db)
            .filter(\.$user.$id == userID)
            .filter(\.$isActive == true)
            .set(\.$isActive, to: false)
            .set(\.$state, to: "idle")
            .update()
    }

    private func makeResponse(_ d: Device) -> DeviceResponse {
        DeviceResponse(
            id:          d.id ?? UUID(),
            name:        d.name,
            modelCode:   d.modelCode,
            state:       d.state,
            isActive:    d.isActive,
            pairingCode: d.pairingCode,
            lastSeenAt:  d.lastSeenAt
        )
    }
}
