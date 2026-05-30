package com.vestel.divise.watch.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "divise_auth")

class TokenStore(private val context: Context) {

    private val tokenKey = stringPreferencesKey("jwt_token")
    private val emailKey = stringPreferencesKey("user_email")

    suspend fun saveToken(token: String, email: String) {
        context.dataStore.edit { prefs ->
            prefs[tokenKey] = token
            prefs[emailKey] = email
        }
    }

    suspend fun getToken(): String? =
        context.dataStore.data.map { it[tokenKey] }.first()

    suspend fun getEmail(): String? =
        context.dataStore.data.map { it[emailKey] }.first()

    suspend fun clear() {
        context.dataStore.edit { it.clear() }
    }
}
