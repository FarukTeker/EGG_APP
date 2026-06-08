import Vapor

func routes(_ app: Application) throws {
    // Health check
    app.get("api", "health") { _ in ["status": "ok"] }

    let api = app.grouped("api", "v1")

    // Public auth routes (UC-02, UC-03, UC-04)
    let authController = AuthController()
    try api.register(collection: authController)

    // Protected routes — require valid JWT
    let protected = api.grouped(JWTAuthMiddleware())

    let deviceController       = DeviceController()
    let presetController       = PresetController()
    let cookController         = CookController()
    let profileController      = ProfileController()
    let notifController        = NotificationController()
    let watchSettingsController = WatchSettingsController()

    try protected.register(collection: deviceController)
    try protected.register(collection: presetController)
    try protected.register(collection: cookController)
    try protected.register(collection: profileController)
    try protected.register(collection: notifController)
    try protected.register(collection: watchSettingsController)
}
