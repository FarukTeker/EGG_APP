import Vapor
import Fluent

// MARK: - UC-05, UC-15: Device CRUD

struct DeviceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let devices = routes.grouped("devices")
        devices.get(use: list)
        devices.post(use: create)
        devices.delete(":deviceID", use: delete)
        devices.patch(":deviceID", "ping", use: ping)
    }

    // GET /api/v1/devices
    func list(req: Request) async throws -> [DeviceResponse] {
        let userID = try req.currentUserID
        return try await Device.query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()
            .map { d in
                DeviceResponse(id: try d.requireID(), name: d.name,
                               modelCode: d.modelCode, state: d.state,
                               isActive: d.isActive, lastSeenAt: d.lastSeenAt)
            }
    }

    // POST /api/v1/devices  — UC-05 pairing
    func create(req: Request) async throws -> DeviceResponse {
        let userID = try req.currentUserID
        let body   = try req.content.decode(CreateDeviceRequest.self)
        guard !body.name.isEmpty else { throw Abort(.badRequest, reason: "Device name required.") }

        // Mark all previous devices idle when adding new active one
        try await Device.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$isActive == true)
            .set(\.$isActive, to: false)
            .set(\.$state, to: "idle")
            .update()

        let device = Device(userID: userID, name: body.name, modelCode: body.modelCode)
        try await device.save(on: req.db)
        return DeviceResponse(id: try device.requireID(), name: device.name,
                              modelCode: device.modelCode, state: device.state,
                              isActive: device.isActive, lastSeenAt: nil)
    }

    // DELETE /api/v1/devices/:deviceID
    func delete(req: Request) async throws -> HTTPStatus {
        let userID   = try req.currentUserID
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

    // PATCH /api/v1/devices/:deviceID/ping — update lastSeenAt
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
}
