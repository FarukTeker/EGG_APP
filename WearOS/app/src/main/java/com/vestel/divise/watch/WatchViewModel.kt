package com.vestel.divise.watch

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.vestel.divise.watch.data.*
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class WatchUiState(
    val isLoggedIn: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null,
    val email: String = "",

    // Pairing
    val devices: List<DeviceResponse> = emptyList(),
    val activeDevice: DeviceResponse? = null,
    val isPairing: Boolean = false,
    val isPaired: Boolean = false,

    // Presets
    val presets: List<PresetResponse> = emptyList(),
    val selectedPresetIndex: Int = 0,

    // Cook config (custom)
    val cookConfig: CookConfig = CookConfig(),
    val currentSlotIndex: Int = 0,

    // Cooking
    val isCooking: Boolean = false,
    val isPaused: Boolean = false,
    val isPreheat: Boolean = false,
    val remainingSeconds: Int = 0,
    val totalSeconds: Int = 0,
    val cookSessionId: String? = null,
    val isDone: Boolean = false,

    // History
    val sessions: List<CookSessionResponse> = emptyList()
) {
    val progress: Float get() = if (totalSeconds > 0) remainingSeconds.toFloat() / totalSeconds else 1f
    val remainingFormatted: String get() = "${remainingSeconds / 60}:%02d".format(remainingSeconds % 60)
    val subRemainingFormatted: String get() {
        val slots = cookConfig.slots.filter { it.active }
        val minTime = slots.minOfOrNull { it.doneness.seconds } ?: 0
        val subRemaining = (remainingSeconds - (totalSeconds - minTime)).coerceAtLeast(0)
        return "${subRemaining / 60}:%02d".format(subRemaining % 60)
    }
}

class WatchViewModel(application: Application) : AndroidViewModel(application) {

    private val tokenStore = TokenStore(application)
    private val api = ApiClient { _state.value.let { if (it.isLoggedIn) token else null } }
    private var token: String? = null

    private val _state = MutableStateFlow(WatchUiState())
    val state = _state.asStateFlow()

    private var timerJob: Job? = null

    init {
        viewModelScope.launch {
            val savedToken = tokenStore.getToken()
            val savedEmail = tokenStore.getEmail()
            if (savedToken != null && savedEmail != null) {
                token = savedToken
                _state.update { it.copy(isLoggedIn = true, email = savedEmail) }
                loadDevicesAndPresets()
            }
        }
    }

    fun login(email: String, password: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            api.login(email, password)
                .onSuccess { auth ->
                    token = auth.token
                    tokenStore.saveToken(auth.token, auth.email)
                    _state.update { it.copy(isLoggedIn = true, isLoading = false, email = auth.email) }
                    loadDevicesAndPresets()
                }
                .onFailure { e ->
                    _state.update { it.copy(isLoading = false, error = e.message) }
                }
        }
    }

    /**
     * Mock "sync with phone" flow for demos. Skips the real backend and drops
     * straight into the app with sample data so it always works offline.
     */
    fun mockSync() {
        _state.update {
            it.copy(
                isLoggedIn = true,
                isLoading = false,
                error = null,
                email = "demo@vestel.com",
                devices = listOf(MOCK_DEVICE),
                activeDevice = MOCK_DEVICE,
                isPaired = true,
                presets = MOCK_PRESETS
            )
        }
    }

    fun logout() {
        viewModelScope.launch {
            tokenStore.clear()
            token = null
            _state.update { WatchUiState() }
        }
    }

    private fun loadDevicesAndPresets() {
        viewModelScope.launch {
            api.getDevices().onSuccess { devices ->
                val active = devices.firstOrNull { it.state == "active" }
                _state.update {
                    it.copy(
                        devices = devices,
                        activeDevice = active,
                        isPaired = active != null
                    )
                }
            }
            api.getPresets().onSuccess { presets ->
                _state.update { it.copy(presets = presets) }
            }
            api.getSessions().onSuccess { sessions ->
                _state.update { it.copy(sessions = sessions) }
            }
        }
    }

    fun startPairing() {
        _state.update { it.copy(isPairing = true, error = null) }
        viewModelScope.launch {
            delay(2000) // search animation
            // Prefer a real cooker when the backend is up and one is registered
            // on the account; otherwise fall back to the mock cooker so pairing
            // always succeeds (the demo backend has no device provisioned).
            val device = if (api.isBackendUp()) {
                api.getDevices().getOrNull()
                    ?.let { devices -> devices.firstOrNull { it.state == "active" } ?: devices.firstOrNull() }
                    ?: MOCK_DEVICE
            } else {
                MOCK_DEVICE
            }
            val usingMock = device === MOCK_DEVICE
            _state.update {
                it.copy(
                    isPairing = false,
                    isPaired = true,
                    devices = listOf(device),
                    activeDevice = device,
                    // The mock cooker ships with sample presets; keep any real
                    // presets already loaded from the backend untouched.
                    presets = if (usingMock && it.presets.isEmpty()) MOCK_PRESETS else it.presets
                )
            }
        }
    }

    fun selectPreset(index: Int) {
        _state.update { it.copy(selectedPresetIndex = index) }
    }

    fun applyPreset(preset: PresetResponse) {
        val slots = preset.selectedSections.mapIndexed { i, _ ->
            val doneness = preset.donenessLevels.getOrNull(i)?.let { Doneness.fromString(it) } ?: Doneness.Medium
            SlotConfig(doneness, true)
        }
        val padded = slots + List((3 - slots.size).coerceAtLeast(0)) { SlotConfig(active = false) }
        _state.update { it.copy(cookConfig = CookConfig(padded.take(3))) }
    }

    fun setSlotDoneness(slotIndex: Int, doneness: Doneness) {
        _state.update { st ->
            val newSlots = st.cookConfig.slots.toMutableList()
            if (slotIndex < newSlots.size) {
                newSlots[slotIndex] = newSlots[slotIndex].copy(doneness = doneness)
            }
            st.copy(cookConfig = CookConfig(newSlots))
        }
    }

    fun setCurrentSlot(index: Int) {
        _state.update { it.copy(currentSlotIndex = index) }
    }

    fun startCook(presetName: String? = null) {
        val st = _state.value
        val config = st.cookConfig
        val total = config.totalSeconds

        _state.update {
            it.copy(
                isPreheat = true,
                totalSeconds = total,
                remainingSeconds = total,
                isDone = false
            )
        }

        viewModelScope.launch {
            delay(2000) // preheat simulation

            val activeSlots = config.slots.withIndex().filter { it.value.active }
            val req = StartCookRequest(
                deviceId = st.activeDevice?.id,
                presetName = presetName,
                mode = "separate",
                selectedSections = activeSlots.map { it.index },
                donenessLevels = config.slots.map { it.doneness.label }
            )
            api.startCookSession(req).onSuccess { session ->
                _state.update { it.copy(cookSessionId = session.id) }
            }

            _state.update { it.copy(isPreheat = false, isCooking = true) }
            startTimer()
        }
    }

    private fun startTimer() {
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            while (_state.value.remainingSeconds > 0) {
                delay(1000)
                if (!_state.value.isPaused) {
                    _state.update { it.copy(remainingSeconds = it.remainingSeconds - 1) }
                }
            }
            // Done
            _state.value.cookSessionId?.let { id ->
                api.updateSession(id, "completed")
            }
            _state.update { it.copy(isCooking = false, isDone = true) }
        }
    }

    fun pauseCook() {
        _state.update { it.copy(isPaused = true) }
    }

    fun resumeCook() {
        _state.update { it.copy(isPaused = false) }
    }

    fun cancelCook() {
        timerJob?.cancel()
        viewModelScope.launch {
            _state.value.cookSessionId?.let { id ->
                api.updateSession(id, "cancelled")
            }
            _state.update {
                it.copy(
                    isCooking = false,
                    isPaused = false,
                    isPreheat = false,
                    remainingSeconds = 0,
                    cookSessionId = null,
                    isDone = false
                )
            }
        }
    }

    fun dismissDone() {
        _state.update { it.copy(isDone = false, cookSessionId = null) }
        viewModelScope.launch {
            api.getSessions().onSuccess { sessions ->
                _state.update { it.copy(sessions = sessions) }
            }
        }
    }

    fun clearError() {
        _state.update { it.copy(error = null) }
    }

    companion object {
        /** Stand-in cooker used by the demo sync and the pairing search. */
        private val MOCK_DEVICE = DeviceResponse(
            id = "mock-device",
            name = "Kitchen",
            modelCode = "DIVISE-1",
            state = "active",
            isActive = true
        )

        /** Sample presets that ship with the mock cooker. */
        private val MOCK_PRESETS = listOf(
            PresetResponse(
                id = "mock-preset-1",
                name = "Breakfast",
                mode = "separate",
                selectedSections = listOf(0, 1, 2),
                donenessLevels = listOf("Hard", "Medium", "Soft")
            ),
            PresetResponse(
                id = "mock-preset-2",
                name = "Soft trio",
                mode = "separate",
                selectedSections = listOf(0, 1, 2),
                donenessLevels = listOf("Soft", "Soft", "Soft")
            ),
            PresetResponse(
                id = "mock-preset-3",
                name = "Medium trio",
                mode = "separate",
                selectedSections = listOf(0, 1, 2),
                donenessLevels = listOf("Medium", "Medium", "Medium")
            ),
            PresetResponse(
                id = "mock-preset-4",
                name = "Hard trio",
                mode = "separate",
                selectedSections = listOf(0, 1, 2),
                donenessLevels = listOf("Hard", "Hard", "Hard")
            ),
            PresetResponse(
                id = "mock-preset-5",
                name = "Brunch",
                mode = "separate",
                selectedSections = listOf(0, 1, 2),
                donenessLevels = listOf("Soft", "Medium", "Medium")
            ),
            PresetResponse(
                id = "mock-preset-6",
                name = "Quick pair",
                mode = "separate",
                selectedSections = listOf(0, 1),
                donenessLevels = listOf("Soft", "Soft")
            ),
            PresetResponse(
                id = "mock-preset-7",
                name = "Single soft",
                mode = "separate",
                selectedSections = listOf(0),
                donenessLevels = listOf("Soft")
            )
        )
    }
}
