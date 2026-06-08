import Vapor
import Fluent

// MARK: - UC-16: Profile (GET/PATCH /api/v1/users/me + avatar upload)

struct ProfileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let me = routes.grouped("users", "me")
        me.get(use: getProfile)
        me.patch(use: updateProfile)
        me.post("avatar", use: uploadAvatar)   // UC-16 "Change photo"
    }

    // GET /api/v1/users/me
    func getProfile(req: Request) async throws -> UserResponse {
        let user = try await req.currentUser()
        return makeResponse(user)
    }

    // PATCH /api/v1/users/me
    func updateProfile(req: Request) async throws -> UserResponse {
        let user = try await req.currentUser()
        let body = try req.content.decode(UpdateProfileRequest.self)
        if let f = body.firstName { user.firstName = f }
        if let l = body.lastName  { user.lastName  = l }
        if let e = body.email, e.contains("@") { user.email = e }
        try await user.save(on: req.db)
        return makeResponse(user)
    }

    // POST /api/v1/users/me/avatar  — UC-16 "Change photo"
    // Accepts { "avatarUrl": "data:image/jpeg;base64,..." } or a remote https URL.
    func uploadAvatar(req: Request) async throws -> UserResponse {
        let user = try await req.currentUser()
        let body = try req.content.decode(UploadAvatarRequest.self)
        guard !body.avatarUrl.isEmpty else {
            throw Abort(.badRequest, reason: "avatarUrl must not be empty.")
        }
        user.avatarUrl = body.avatarUrl
        try await user.save(on: req.db)
        return makeResponse(user)
    }

    // MARK: - Helper

    private func makeResponse(_ u: User) -> UserResponse {
        UserResponse(
            id:        (try? u.requireID()) ?? UUID(),
            firstName: u.firstName,
            lastName:  u.lastName,
            email:     u.email,
            avatarUrl: u.avatarUrl,
            createdAt: u.createdAt
        )
    }
}
