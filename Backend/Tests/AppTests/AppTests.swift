import XCTVapor
import Foundation
@testable import App

// Codable test helpers
private struct RegBody: Content { let firstName,lastName,email,password: String }
private struct LoginBody: Content { let email,password: String }
private struct DeviceBody: Content { let name,modelCode: String }
private struct SessionBody: Content { let mode:String; let selectedSections:[Int]; let donenessLevels:[String] }
private struct StatusBody: Content { let status: String }
private struct PresetBody: Content { let name,mode:String; let selectedSections:[Int]; let donenessLevels:[String] }
private struct NotifBody: Content { let cookComplete: Bool? }

final class AppTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = Application(.testing)
        app.databases.use(.sqlite(.memory), as: .sqlite)
        try await configure(app)
    }

    override func tearDown() async throws {
        app.shutdown()
    }

    // MARK: - UC-02: Register

    func testRegisterSuccess() async throws {
        try await app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode([
                "firstName": "Ahmet",
                "lastName":  "Yılmaz",
                "email":     "ahmet@vestel.com",
                "password":  "secure123"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let body = try res.content.decode(AuthResponse.self)
            XCTAssertFalse(body.token.isEmpty)
            XCTAssertEqual(body.email, "ahmet@vestel.com")
        })
    }

    func testRegisterDuplicateEmail() async throws {
        let payload = ["firstName":"A","lastName":"B","email":"dup@test.com","password":"secure123"]
        try await app.test(.POST, "api/v1/auth/register") { req in try req.content.encode(payload) } afterResponse: { _ in }
        try await app.test(.POST, "api/v1/auth/register") { req in try req.content.encode(payload) } afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        }
    }

    func testRegisterWeakPassword() async throws {
        try await app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode(["firstName":"A","lastName":"B","email":"x@x.com","password":"123"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })
    }

    // MARK: - UC-03: Login

    func testLoginSuccess() async throws {
        // Register first
        try await app.test(.POST, "api/v1/auth/register") { req in
            try req.content.encode(["firstName":"A","lastName":"B","email":"login@test.com","password":"secure123"])
        } afterResponse: { _ in }

        // Then login
        try await app.test(.POST, "api/v1/auth/login", beforeRequest: { req in
            try req.content.encode(["email":"login@test.com","password":"secure123"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let body = try res.content.decode(AuthResponse.self)
            XCTAssertFalse(body.token.isEmpty)
        })
    }

    func testLoginWrongPassword() async throws {
        try await app.test(.POST, "api/v1/auth/register") { req in
            try req.content.encode(["firstName":"A","lastName":"B","email":"wp@test.com","password":"correct123"])
        } afterResponse: { _ in }

        try await app.test(.POST, "api/v1/auth/login", beforeRequest: { req in
            try req.content.encode(["email":"wp@test.com","password":"wrong"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }

    // MARK: - UC-05: Devices

    func testCreateAndListDevice() async throws {
        let token = try await registerAndGetToken()

        try await app.test(.POST, "api/v1/devices", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
            try req.content.encode(DeviceBody(name: "Kitchen Cooker", modelCode: "VS-EG-2025"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        try await app.test(.GET, "api/v1/devices", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let devices = try res.content.decode([DeviceResponse].self)
            XCTAssertEqual(devices.count, 1)
            XCTAssertEqual(devices[0].name, "Kitchen Cooker")
        })
    }

    // MARK: - UC-06: Cook Session

    func testStartAndCompleteCook() async throws {
        let token = try await registerAndGetToken()

        // Start cook
        var sessionID: UUID?
        try await app.test(.POST, "api/v1/cook/sessions", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
            try req.content.encode(SessionBody(mode:"bulk", selectedSections:[0,1,2], donenessLevels:["Medium","Medium","Medium"]))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let session = try res.content.decode(CookSessionResponse.self)
            XCTAssertEqual(session.status, "active")
            sessionID = session.id
        })

        // Complete cook
        guard let sid = sessionID else { XCTFail("No session"); return }
        try await app.test(.PATCH, "api/v1/cook/sessions/\(sid)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
            try req.content.encode(StatusBody(status: "completed"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let session = try res.content.decode(CookSessionResponse.self)
            XCTAssertEqual(session.status, "completed")
        })
    }

    // MARK: - UC-09: Presets

    func testCreateAndDeletePreset() async throws {
        let token = try await registerAndGetToken()

        var presetID: UUID?
        try await app.test(.POST, "api/v1/presets", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
            try req.content.encode(PresetBody(name:"Sunday Brunch", mode:"bulk", selectedSections:[0,1,2], donenessLevels:["Medium","Medium","Medium"]))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let preset = try res.content.decode(PresetResponse.self)
            XCTAssertEqual(preset.name, "Sunday Brunch")
            presetID = preset.id
        })

        guard let pid = presetID else { XCTFail("No preset"); return }
        try await app.test(.DELETE, "api/v1/presets/\(pid)", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .noContent)
        })
    }

    // MARK: - UC-17: Notification Prefs

    func testGetAndUpdateNotifPrefs() async throws {
        let token = try await registerAndGetToken()

        try await app.test(.GET, "api/v1/notifications/preferences", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let prefs = try res.content.decode(NotificationPrefsResponse.self)
            XCTAssertTrue(prefs.cookComplete)
        })

        try await app.test(.PUT, "api/v1/notifications/preferences", beforeRequest: { req in
            req.headers.bearerAuthorization = .init(token: token)
            try req.content.encode(NotifBody(cookComplete: false))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let prefs = try res.content.decode(NotificationPrefsResponse.self)
            XCTAssertFalse(prefs.cookComplete)
        })
    }

    // MARK: - Auth guard test

    func testProtectedRouteRequiresToken() async throws {
        try await app.test(.GET, "api/v1/devices") { res in
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    // MARK: - Health check

    func testHealthCheck() async throws {
        try await app.test(.GET, "api/health") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    // MARK: - Helpers

    private func registerAndGetToken() async throws -> String {
        var token = ""
        try await app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode([
                "firstName": "Test",
                "lastName":  "User",
                "email":     "test\(UUID())@vestel.com",
                "password":  "secure123"
            ])
        }, afterResponse: { res in
            let body = try res.content.decode(AuthResponse.self)
            token = body.token
        })
        return token
    }
}
