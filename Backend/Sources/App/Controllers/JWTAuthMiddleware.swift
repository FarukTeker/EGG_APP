import Vapor
import JWT

// JWT guard middleware — attached to all protected routes

struct JWTAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        _ = try request.jwt.verify(as: UserPayload.self)
        return try await next.respond(to: request)
    }
}

// Convenience extension — get current user from token

extension Request {
    var currentUserID: UUID {
        get throws {
            let payload = try jwt.verify(as: UserPayload.self)
            return payload.userID
        }
    }

    func currentUser() async throws -> User {
        let id = try currentUserID
        guard let user = try await User.find(id, on: db) else {
            throw Abort(.unauthorized)
        }
        return user
    }
}
