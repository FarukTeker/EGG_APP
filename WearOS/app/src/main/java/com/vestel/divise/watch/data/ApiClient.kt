package com.vestel.divise.watch.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

class ApiClient(private val tokenProvider: () -> String?) {

    // 10.0.2.2 = host machine from Android emulator
    private var baseUrl = "http://10.0.2.2:8080/api/v1"

    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    private val jsonMedia = "application/json".toMediaType()

    private fun authRequest(path: String): Request.Builder {
        val builder = Request.Builder().url("$baseUrl$path")
        tokenProvider()?.let { builder.addHeader("Authorization", "Bearer $it") }
        return builder
    }

    suspend fun login(email: String, password: String): Result<AuthResponse> = withContext(Dispatchers.IO) {
        runCatching {
            val body = json.encodeToString(LoginRequest(email, password)).toRequestBody(jsonMedia)
            val request = Request.Builder()
                .url("$baseUrl/auth/login")
                .post(body)
                .build()
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) error("Login failed: ${response.code}")
            json.decodeFromString<AuthResponse>(response.body!!.string())
        }
    }

    suspend fun getDevices(): Result<List<DeviceResponse>> = withContext(Dispatchers.IO) {
        runCatching {
            val request = authRequest("/devices").get().build()
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) error("Devices fetch failed: ${response.code}")
            json.decodeFromString<List<DeviceResponse>>(response.body!!.string())
        }
    }

    suspend fun getPresets(): Result<List<PresetResponse>> = withContext(Dispatchers.IO) {
        runCatching {
            val request = authRequest("/presets").get().build()
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) error("Presets fetch failed: ${response.code}")
            json.decodeFromString<List<PresetResponse>>(response.body!!.string())
        }
    }

    suspend fun startCookSession(req: StartCookRequest): Result<CookSessionResponse> = withContext(Dispatchers.IO) {
        runCatching {
            val body = json.encodeToString(req).toRequestBody(jsonMedia)
            val request = authRequest("/cook/sessions").post(body).build()
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) error("Start cook failed: ${response.code}")
            json.decodeFromString<CookSessionResponse>(response.body!!.string())
        }
    }

    suspend fun updateSession(sessionId: String, status: String): Result<CookSessionResponse> = withContext(Dispatchers.IO) {
        runCatching {
            val body = json.encodeToString(UpdateSessionRequest(status)).toRequestBody(jsonMedia)
            val request = authRequest("/cook/sessions/$sessionId").patch(body).build()
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) error("Update session failed: ${response.code}")
            json.decodeFromString<CookSessionResponse>(response.body!!.string())
        }
    }

    suspend fun getSessions(): Result<List<CookSessionResponse>> = withContext(Dispatchers.IO) {
        runCatching {
            val request = authRequest("/cook/sessions").get().build()
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) error("Sessions fetch failed: ${response.code}")
            json.decodeFromString<List<CookSessionResponse>>(response.body!!.string())
        }
    }
}
