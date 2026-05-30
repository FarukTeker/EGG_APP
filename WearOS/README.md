# Vestel Divisé — Wear OS Companion App

Wear OS watch app for the Vestel Divisé Smart Egg Cooker. Companion to the iOS app, consuming the same Vapor REST backend.

## Screens (21-screen wireframe → 13 implemented screens)

| Screen | Description |
|--------|-------------|
| Splash | Brand splash with Vestel Divisé logo |
| Login | Email + password authentication |
| Pairing | Animated device search with pulsing rings |
| Connected | Green checkmark confirmation |
| Presets | Scrollable preset list (Morning Routine, Sunday Brunch, etc.) |
| Hardness Picker | Per-slot doneness selector (Soft/Medium/Hard) with wheel UI |
| Summary | Cook overview showing slots + total time |
| Preheat | Water heating animation |
| Cooking | Timer ring with countdown, pause/stop controls |
| Cancel Confirm | "Stop cooking?" confirmation dialog |
| Done | Completed cook with dismiss action |
| History | Recent cooking sessions list |
| Settings | Haptics, chime, auto-start toggles + logout |

## Architecture

- **Language:** Kotlin
- **UI:** Jetpack Compose for Wear OS
- **Architecture:** MVVM (single WatchViewModel)
- **Networking:** OkHttp + kotlinx.serialization
- **Token Storage:** DataStore Preferences
- **Navigation:** Wear Compose Navigation (SwipeDismissable)

## Backend Connection

The app connects to the Vapor backend at `http://10.0.2.2:8080` (Android emulator's alias for host localhost).

### Required endpoints:
- `POST /api/v1/auth/login` — JWT authentication
- `GET /api/v1/devices` — List paired devices
- `GET /api/v1/presets` — List cooking presets
- `POST /api/v1/cook/sessions` — Start a cook session
- `PATCH /api/v1/cook/sessions/:id` — Update session (complete/cancel)
- `GET /api/v1/cook/sessions` — Cooking history

## Running

### Prerequisites
1. Android Studio with Wear OS SDK (API 30+)
2. Wear OS emulator (Large Round recommended)
3. Backend running on localhost:8080 (via WSL)

### Backend (WSL Ubuntu)
```bash
export PATH=/usr/local/usr/bin:$PATH
cd /mnt/c/Codes/318yumurta/app/EGG_APP/Backend
swift build          # first time only
.build/debug/App serve --hostname 0.0.0.0 --port 8080
```

### Test credentials
- Email: `yusuf@test.com`
- Password: `test1234`

### Watch App
1. Open `WearOS/` folder in Android Studio
2. Select the Wear OS emulator
3. Run (green play button)

## Design Tokens (from wireframe)

| Token | Value |
|-------|-------|
| Watch background | `#1A1A1C` |
| Page background | `#0A0A0A` |
| Primary (red) | `#FF3B30` |
| Secondary (orange) | `#FF9500` |
| Soft indicator | `#FFD60A` (yellow) |
| Success (green) | `#34C759` |
| Water (blue) | `#0A84FF` |
| Ring track | `rgba(255,255,255,0.14)` |
