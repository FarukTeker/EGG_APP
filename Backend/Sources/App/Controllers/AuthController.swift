import Vapor
import Fluent
import JWT

// MARK: - UC-02 Register / UC-03 Login / UC-04 Password Reset

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register",        use: register)
        auth.post("login",           use: login)
        auth.post("change-password", use: changePassword)
        auth.post("forgot-password", use: forgotPassword)   // UC-04 step 1
        auth.post("reset-password",  use: resetPassword)    // UC-04 step 2
    }

    // POST /api/v1/auth/register
    func register(req: Request) async throws -> AuthResponse {
        let body = try req.content.decode(RegisterRequest.self)
        try body.validate()

        let exists = try await User.query(on: req.db)
            .filter(\.$email == body.email).first()
        guard exists == nil else { throw Abort(.conflict, reason: "Email already registered.") }

        let hash = try Bcrypt.hash(body.password)
        let user = User(firstName: body.firstName, lastName: body.lastName,
                        email: body.email, passwordHash: hash)
        try await user.save(on: req.db)

        let prefs = NotificationPrefs(userID: try user.requireID())
        try await prefs.save(on: req.db)

        return try makeAuthResponse(for: user, req: req)
    }

    // POST /api/v1/auth/login
    func login(req: Request) async throws -> AuthResponse {
        let body = try req.content.decode(LoginRequest.self)
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == body.email).first()
        else { throw Abort(.unauthorized, reason: "Invalid email or password.") }

        guard try user.verify(password: body.password) else {
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }
        return try makeAuthResponse(for: user, req: req)
    }

    // POST /api/v1/auth/change-password  (requires valid JWT in header)
    func changePassword(req: Request) async throws -> HTTPStatus {
        let payload = try req.jwt.verify(as: UserPayload.self)
        let body    = try req.content.decode(ChangePasswordRequest.self)
        guard body.newPassword.count >= 8 else {
            throw Abort(.badRequest, reason: "Password must be 8+ characters.")
        }
        guard let user = try await User.find(payload.userID, on: req.db) else {
            throw Abort(.notFound)
        }
        guard try user.verify(password: body.currentPassword) else {
            throw Abort(.unauthorized, reason: "Current password incorrect.")
        }
        user.passwordHash = try Bcrypt.hash(body.newPassword)
        try await user.save(on: req.db)
        return .ok
    }

    // POST /api/v1/auth/forgot-password  — UC-04 "Send reset link"
    // In production this would send an email; in dev the token is returned directly.
    func forgotPassword(req: Request) async throws -> ForgotPasswordResponse {
        let body = try req.content.decode(ForgotPasswordRequest.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == body.email).first()
        else {
            // Return generic message to avoid user enumeration
            return ForgotPasswordResponse(
                message: "If that email is registered, a reset link has been sent.",
                resetToken: ""
            )
        }

        // Invalidate any existing tokens for this user
        let existing = try await PasswordResetToken.query(on: req.db)
            .filter(\.$user.$id == (try user.requireID()))
            .filter(\.$usedAt == .null)
            .all()
        for t in existing { t.usedAt = Date(); try await t.save(on: req.db) }

        let resetToken = PasswordResetToken(userID: try user.requireID())
        try await resetToken.save(on: req.db)

        return ForgotPasswordResponse(
            message: "If that email is registered, a reset link has been sent.",
            resetToken: resetToken.token  // dev only — would be emailed in prod
        )
    }

    // POST /api/v1/auth/reset-password  — UC-04 "Update password"
    func resetPassword(req: Request) async throws -> HTTPStatus {
        let body = try req.content.decode(ResetPasswordRequest.self)
        guard body.newPassword.count >= 8 else {
            throw Abort(.badRequest, reason: "Password must be 8+ characters.")
        }

        guard let resetToken = try await PasswordResetToken.query(on: req.db)
            .filter(\.$token == body.token)
            .with(\.$user)
            .first()
        else { throw Abort(.badRequest, reason: "Invalid or expired reset token.") }

        guard resetToken.isValid else {
            throw Abort(.gone, reason: "Reset token has expired or was already used.")
        }

        resetToken.user.passwordHash = try Bcrypt.hash(body.newPassword)
        resetToken.usedAt = Date()
        try await resetToken.user.save(on: req.db)
        try await resetToken.save(on: req.db)
        return .ok
    }

    // MARK: - Helper

    private func makeAuthResponse(for user: User, req: Request) throws -> AuthResponse {
        let userID = try user.requireID()
        let payload = UserPayload(
            subject:    .init(value: userID.uuidString),
            expiration: .init(value: Date().addingTimeInterval(60 * 60 * 24 * 7)),
            userID:     userID
        )
        let token = try req.jwt.sign(payload)
        return AuthResponse(token: token, userId: userID, email: user.email)
    }
}
