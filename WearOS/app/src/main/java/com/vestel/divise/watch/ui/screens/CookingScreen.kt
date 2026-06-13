package com.vestel.divise.watch.ui.screens

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Text
import com.vestel.divise.watch.ui.components.IconButton
import com.vestel.divise.watch.ui.components.PillButton
import com.vestel.divise.watch.ui.components.TimerRing
import com.vestel.divise.watch.ui.components.TimerSegment
import com.vestel.divise.watch.ui.theme.DiviseColors

@Composable
fun PreheatScreen() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("~", color = DiviseColors.Orange, fontSize = 36.sp)

            Spacer(modifier = Modifier.height(8.dp))
            Text("Heating water", color = DiviseColors.Text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(4.dp))
            Text("~ 0:45 to boil", color = DiviseColors.TextDim, fontSize = 11.sp)
        }
    }
}

/** A "+M:SS Type" line under the main countdown for a later-finishing egg. */
data class CookTimeLine(val label: String, val color: Color)

@Composable
fun CookingActiveScreen(
    remaining: String,
    nextLines: List<CookTimeLine>,
    progress: Float,
    isPaused: Boolean,
    segments: List<TimerSegment>,
    onStop: () -> Unit,
    onPauseResume: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        // The ring fills the watch face; time + controls live inside it.
        TimerRing(
            progress = progress,
            modifier = Modifier
                .fillMaxSize()
                .padding(4.dp),
            strokeWidth = 8.dp,
            dim = isPaused,
            segments = segments
        )

        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = remaining,
                color = if (isPaused) DiviseColors.TextDim else DiviseColors.Text,
                fontSize = 38.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.5.sp
            )
            if (isPaused) {
                Text(
                    text = "PAUSED",
                    color = DiviseColors.Orange,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 0.6.sp
                )
            } else {
                // "+M:SS Type" for each later-finishing egg, colour-coded.
                nextLines.forEach { line ->
                    Text(
                        text = line.label,
                        color = line.color,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                // Stop button
                IconButton(
                    onClick = onStop,
                    size = 38.dp,
                    color = if (isPaused) DiviseColors.Surface12 else DiviseColors.Red
                ) {
                    Box(
                        modifier = Modifier
                            .size(13.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(Color.White)
                    )
                }

                // Pause/Resume button
                IconButton(
                    onClick = onPauseResume,
                    size = 38.dp,
                    color = DiviseColors.Red
                ) {
                    if (isPaused) {
                        // Play icon
                        Text("▶", color = Color.White, fontSize = 13.sp)
                    } else {
                        // Pause icon
                        Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                            Box(
                                modifier = Modifier
                                    .width(4.dp)
                                    .height(13.dp)
                                    .clip(RoundedCornerShape(1.dp))
                                    .background(Color.White)
                            )
                            Box(
                                modifier = Modifier
                                    .width(4.dp)
                                    .height(13.dp)
                                    .clip(RoundedCornerShape(1.dp))
                                    .background(Color.White)
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun CancelConfirmScreen(
    onKeep: () -> Unit,
    onStop: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 18.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(androidx.compose.foundation.shape.CircleShape)
                    .background(DiviseColors.Red),
                contentAlignment = Alignment.Center
            ) {
                Text("!", color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
            }

            Spacer(modifier = Modifier.height(8.dp))
            Text(
                "Stop cooking?",
                color = DiviseColors.Text,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                "Eggs will be undercooked",
                color = DiviseColors.TextDim,
                fontSize = 11.sp,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                PillButton(
                    text = "Keep",
                    onClick = onKeep,
                    color = DiviseColors.Surface12,
                    modifier = Modifier.weight(1f)
                )
                PillButton(
                    text = "Stop",
                    onClick = onStop,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
fun DoneScreen(onDismiss: () -> Unit) {
    val context = LocalContext.current

    // Buzz repeatedly while the Done screen is shown; stops when it leaves
    // composition (i.e. when the user taps Dismiss).
    DisposableEffect(Unit) {
        val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Pattern repeats: wait 0ms, buzz 500ms, pause 800ms (index 0 = repeat point)
            val effect = VibrationEffect.createWaveform(longArrayOf(0, 500, 800), 0)
            vibrator?.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(longArrayOf(0, 500, 800), 0)
        }
        onDispose { vibrator?.cancel() }
    }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        // Same full-face ring as the cooking screen; content + button live inside.
        TimerRing(
            progress = 1f,
            modifier = Modifier
                .fillMaxSize()
                .padding(4.dp),
            strokeWidth = 8.dp,
            dim = true
        )

        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text("Done!", color = DiviseColors.Text, fontSize = 30.sp, fontWeight = FontWeight.SemiBold)
            Text("0:00", color = DiviseColors.TextDim, fontSize = 13.sp)

            Spacer(modifier = Modifier.height(12.dp))

            PillButton(text = "Dismiss", onClick = onDismiss, color = DiviseColors.Red)
        }
    }
}
