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
        _state.update { it.copy(isPairing = true) }
        viewModelScope.launch {
            delay(2000)
            api.getDevices().onSuccess { devices ->
                val active = devices.firstOrNull { it.state == "active" } ?: devices.firstOrNull()
                _state.update {
                    it.copy(
                        isPairing = false,
                        isPaired = active != null,
                        devices = devices,
                        activeDevice = active
                    )
                }
            }.onFailure {
                _state.update { it.copy(isPairing = false, error = "Could not find device") }
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
}
