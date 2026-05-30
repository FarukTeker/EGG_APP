import Vapor
import Fluent

// MARK: - UC-16: Profile (GET/PATCH /api/v1/users/me)

struct ProfileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users", "me")
        users.get(use: getProfile)
        users.patch(use: updateProfile)
    }

    // GET /api/v1/users/me
    func getProfile(req: Request) async throws -> UserResponse {
        let user = try await req.currentUser()
        return UserResponse(
            id:        try user.requireID(),
            firstName: user.firstName,
            lastName:  user.lastName,
            email:     user.email,
            createdAt: user.createdAt
        )
    }

    // PATCH /api/v1/users/me
    func updateProfile(req: Request) async throws -> UserResponse {
        let user = try await req.currentUser()
        let body = try req.content.decode(UpdateProfileRequest.self)
        if let f = body.firstName { user.firstName = f }
        if let l = body.lastName  { user.lastName  = l }
        if let e = body.email, e.contains("@") { user.email = e }
        try await user.save(on: req.db)
        return UserResponse(
            id:        try user.requireID(),
            firstName: user.firstName,
            lastName:  user.lastName,
            email:     user.email,
            createdAt: user.createdAt
        )
    }
}
