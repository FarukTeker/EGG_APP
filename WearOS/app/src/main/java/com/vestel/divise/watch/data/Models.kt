package com.vestel.divise.watch.data

import kotlinx.serialization.Serializable

@Serializable
data class AuthResponse(
    val token: String,
    val userId: String,
    val email: String
)

@Serializable
data class LoginRequest(
    val email: String,
    val password: String
)

@Serializable
data class DeviceResponse(
    val id: String,
    val name: String,
    val modelCode: String,
    val state: String,
    val isActive: Boolean,
    val lastSeenAt: String? = null
)

@Serializable
data class PresetResponse(
    val id: String,
    val name: String,
    val mode: String,
    val selectedSections: List<Int>,
    val donenessLevels: List<String>,
    val updatedAt: String? = null
)

@Serializable
data class StartCookRequest(
    val deviceId: String? = null,
    val presetName: String? = null,
    val mode: String,
    val selectedSections: List<Int>,
    val donenessLevels: List<String>
)

@Serializable
data class CookSessionResponse(
    val id: String,
    val presetName: String? = null,
    val mode: String,
    val selectedSections: List<Int>,
    val donenessLevels: List<String>,
    val status: String,
    val startedAt: String? = null,
    val completedAt: String? = null
)

@Serializable
data class UpdateSessionRequest(
    val status: String
)

enum class Doneness(val label: String, val shortLabel: String, val minutes: String, val seconds: Int) {
    Soft("Soft", "S", "3:30", 210),
    Medium("Medium", "M", "4:30", 270),
    Hard("Hard", "H", "5:30", 330);

    companion object {
        fun fromString(s: String): Doneness = when (s.lowercase()) {
            "soft" -> Soft
            "medium" -> Medium
            "hard" -> Hard
            else -> Medium
        }
    }
}

data class SlotConfig(
    val doneness: Doneness = Doneness.Medium,
    val active: Boolean = true
)

data class CookConfig(
    val slots: List<SlotConfig> = listOf(
        SlotConfig(Doneness.Hard),
        SlotConfig(Doneness.Medium),
        SlotConfig(Doneness.Soft)
    )
) {
    val totalSeconds: Int get() = slots.filter { it.active }.maxOfOrNull { it.doneness.seconds } ?: 0
    val totalTimeFormatted: String get() {
        val s = totalSeconds
        return "${s / 60}:%02d".format(s % 60)
    }
}
