package com.vestel.divise.watch

import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.vestel.divise.watch.data.Doneness
import com.vestel.divise.watch.ui.screens.*

object Routes {
    const val SPLASH = "splash"
    const val LOGIN = "login"
    const val PAIRING = "pairing"
    const val CONNECTED = "connected"
    const val PRESETS = "presets"
    const val HARDNESS = "hardness"
    const val SUMMARY = "summary"
    const val PREHEAT = "preheat"
    const val COOKING = "cooking"
    const val CANCEL_CONFIRM = "cancel_confirm"
    const val DONE = "done"
    const val HISTORY = "history"
    const val SETTINGS = "settings"
}

@Composable
fun WatchApp(viewModel: WatchViewModel) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val navController = rememberSwipeDismissableNavController()

    val startDest = when {
        !state.isLoggedIn -> Routes.SPLASH
        !state.isPaired -> Routes.PAIRING
        state.isDone -> Routes.DONE
        state.isCooking || state.isPaused -> Routes.COOKING
        state.isPreheat -> Routes.PREHEAT
        else -> Routes.PRESETS
    }

    LaunchedEffect(state.isLoggedIn, state.isPaired, state.isDone, state.isCooking) {
        val target = when {
            !state.isLoggedIn -> Routes.LOGIN
            !state.isPaired -> Routes.PAIRING
            state.isDone -> Routes.DONE
            state.isCooking || state.isPaused -> Routes.COOKING
            state.isPreheat -> Routes.PREHEAT
            else -> return@LaunchedEffect
        }
        if (navController.currentDestination?.route != target) {
            navController.navigate(target) {
                popUpTo(0) { inclusive = true }
            }
        }
    }

    SwipeDismissableNavHost(
        navController = navController,
        startDestination = startDest
    ) {
        composable(Routes.SPLASH) {
            SplashScreen(onTimeout = {
                if (state.isLoggedIn) {
                    if (state.isPaired) navController.navigate(Routes.PRESETS) { popUpTo(0) { inclusive = true } }
                    else navController.navigate(Routes.PAIRING) { popUpTo(0) { inclusive = true } }
                } else {
                    navController.navigate(Routes.LOGIN) { popUpTo(0) { inclusive = true } }
                }
            })
        }

        composable(Routes.LOGIN) {
            LoginScreen(
                isLoading = state.isLoading,
                error = state.error,
                onLogin = { email, password -> viewModel.login(email, password) },
                onSync = {
                    viewModel.mockSync()
                    navController.navigate(Routes.PRESETS) { popUpTo(0) { inclusive = true } }
                }
            )
        }

        composable(Routes.PAIRING) {
            PairingScreen(
                isPairing = state.isPairing,
                onStartPairing = { viewModel.startPairing() }
            )
        }

        composable(Routes.CONNECTED) {
            ConnectedScreen(
                deviceName = state.activeDevice?.name ?: "Kitchen",
                onContinue = {
                    navController.navigate(Routes.PRESETS) { popUpTo(0) { inclusive = true } }
                }
            )
        }

        composable(Routes.PRESETS) {
            PresetsScreen(
                presets = state.presets,
                selectedIndex = state.selectedPresetIndex,
                onSelect = { viewModel.selectPreset(it) },
                onUse = {
                    val preset = state.presets.getOrNull(state.selectedPresetIndex)
                    if (preset != null) {
                        viewModel.applyPreset(preset)
                        navController.navigate(Routes.SUMMARY)
                    }
                },
                onCustom = {
                    viewModel.setCurrentSlot(0)
                    navController.navigate(Routes.HARDNESS)
                }
            )
        }

        composable(Routes.HARDNESS) {
            val slotIndex = state.currentSlotIndex
            val activeSlots = state.cookConfig.slots.filter { it.active }
            val totalSlots = activeSlots.size.coerceAtLeast(3)

            HardnessPickerScreen(
                slotIndex = slotIndex,
                totalSlots = totalSlots,
                currentDoneness = state.cookConfig.slots.getOrNull(slotIndex)?.doneness ?: Doneness.Medium,
                onSelect = { doneness -> viewModel.setSlotDoneness(slotIndex, doneness) },
                onDone = {
                    if (slotIndex < totalSlots - 1) {
                        viewModel.setCurrentSlot(slotIndex + 1)
                    } else {
                        navController.navigate(Routes.SUMMARY)
                    }
                }
            )
        }

        composable(Routes.SUMMARY) {
            SummaryScreen(
                slots = state.cookConfig.slots.map { it.doneness to it.active },
                totalTime = state.cookConfig.totalTimeFormatted,
                onStart = {
                    val preset = state.presets.getOrNull(state.selectedPresetIndex)
                    viewModel.startCook(presetName = preset?.name)
                }
            )
        }

        composable(Routes.PREHEAT) {
            PreheatScreen()
        }

        composable(Routes.COOKING) {
            CookingActiveScreen(
                remaining = state.remainingFormatted,
                subRemaining = state.subRemainingFormatted,
                progress = state.progress,
                isPaused = state.isPaused,
                onStop = { navController.navigate(Routes.CANCEL_CONFIRM) },
                onPauseResume = {
                    if (state.isPaused) viewModel.resumeCook() else viewModel.pauseCook()
                }
            )
        }

        composable(Routes.CANCEL_CONFIRM) {
            CancelConfirmScreen(
                onKeep = { navController.popBackStack() },
                onStop = {
                    viewModel.cancelCook()
                    navController.navigate(Routes.PRESETS) { popUpTo(0) { inclusive = true } }
                }
            )
        }

        composable(Routes.DONE) {
            DoneScreen(onDismiss = {
                viewModel.dismissDone()
                navController.navigate(Routes.HISTORY) { popUpTo(0) { inclusive = true } }
            })
        }

        composable(Routes.HISTORY) {
            HistoryScreen(sessions = state.sessions)
        }

        composable(Routes.SETTINGS) {
            SettingsScreen(onLogout = {
                viewModel.logout()
            })
        }
    }
}
