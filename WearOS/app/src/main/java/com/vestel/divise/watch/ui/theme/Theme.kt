package com.vestel.divise.watch.ui.theme

import androidx.compose.ui.graphics.Color
import com.vestel.divise.watch.data.Doneness

/**
 * Light / dark palette selection for the watch app.
 *
 * There is intentionally **no in-app theme switcher**. On a real build the watch
 * is meant to follow the paired phone's appearance, so the user never toggles it
 * here. Until that phone-sync is wired up, flip [ThemeConfig.mode] in code to
 * preview either palette — every screen reads its colors through [DiviseColors],
 * so changing this one value re-themes the whole app on the next build.
 */
enum class ThemeMode { Dark, Light }

object ThemeConfig {
    /** Change this single value to switch the whole app between dark and light. */
    var mode: ThemeMode = ThemeMode.Dark
}

private data class Palette(
    val watchBg: Color,
    val pageBg: Color,
    val cardBg: Color,
    val border: Color,
    val text: Color,
    val textDim: Color,
    val textMute: Color,
    val red: Color,
    val redDim: Color,
    val orange: Color,
    val yellow: Color,
    val green: Color,
    val blue: Color,
    val ringTrack: Color,
    val surfaceDim: Color,
    val surface12: Color,
)

private val DarkPalette = Palette(
    watchBg = Color(0xFF1A1A1C),
    pageBg = Color(0xFF0A0A0A),
    cardBg = Color(0xFF262628),
    border = Color(0x0FFFFFFF),
    text = Color.White,
    textDim = Color(0x8CFFFFFF),
    textMute = Color(0x52FFFFFF),
    red = Color(0xFFFF3B30),
    redDim = Color(0xFFC62A22),
    orange = Color(0xFFFF9500),
    yellow = Color(0xFFFFD60A),
    green = Color(0xFF34C759),
    blue = Color(0xFF0A84FF),
    ringTrack = Color(0x24FFFFFF),
    surfaceDim = Color(0x0DFFFFFF),
    surface12 = Color(0x1FFFFFFF),
)

// Light palette mirrors the phone app's light tokens (Sources/Design/DesignSystem.swift):
// bgApp #EEE7E1, bgSurface1 #E2DCD5, bgSurface2 #D6CFC6, fg1 #2B2B2B, fg2 #6B6B6B, fg3 #9B9B9B.
// Neutral hairlines/overlays flip to black at the same alpha; brand accents stay identical.
private val LightPalette = Palette(
    watchBg = Color(0xFFE2DCD5),
    pageBg = Color(0xFFEEE7E1),
    cardBg = Color(0xFFD6CFC6),
    border = Color(0x14000000),
    text = Color(0xFF2B2B2B),
    textDim = Color(0xFF6B6B6B),
    textMute = Color(0xFF9B9B9B),
    red = Color(0xFFFF3B30),
    redDim = Color(0xFFC62A22),
    orange = Color(0xFFFF9500),
    yellow = Color(0xFFFFD60A),
    green = Color(0xFF34C759),
    blue = Color(0xFF0A84FF),
    ringTrack = Color(0x24000000),
    surfaceDim = Color(0x0D000000),
    surface12 = Color(0x1F000000),
)

object DiviseColors {
    private val p: Palette
        get() = if (ThemeConfig.mode == ThemeMode.Light) LightPalette else DarkPalette

    val WatchBg get() = p.watchBg
    val PageBg get() = p.pageBg
    val CardBg get() = p.cardBg
    val Border get() = p.border
    val Text get() = p.text
    val TextDim get() = p.textDim
    val TextMute get() = p.textMute
    val Red get() = p.red
    val RedDim get() = p.redDim
    val Orange get() = p.orange
    val Yellow get() = p.yellow
    val Green get() = p.green
    val Blue get() = p.blue
    val RingTrack get() = p.ringTrack
    val SurfaceDim get() = p.surfaceDim
    val Surface12 get() = p.surface12
}

/**
 * Single source of truth for doneness colours across the app:
 * earliest-cooking Soft is blue, Medium yellow, Hard (latest) red.
 */
fun donenessColor(doneness: Doneness): Color = when (doneness) {
    Doneness.Soft -> DiviseColors.Blue
    Doneness.Medium -> DiviseColors.Yellow
    Doneness.Hard -> DiviseColors.Red
}
