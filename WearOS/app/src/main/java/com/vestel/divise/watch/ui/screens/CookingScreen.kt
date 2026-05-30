package com.vestel.divise.watch.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Text
import com.vestel.divise.watch.ui.components.IconButton
import com.vestel.divise.watch.ui.components.PillButton
import com.vestel.divise.watch.ui.components.TimerRing
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

@Composable
fun CookingActiveScreen(
    remaining: String,
    subRemaining: String,
    progress: Float,
    isPaused: Boolean,
    onStop: () -> Unit,
    onPauseResume: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                modifier = Modifier.size(150.dp),
                contentAlignment = Alignment.Center
            ) {
                TimerRing(
                    progress = progress,
                    size = 150.dp,
                    strokeWidth = 6.dp,
                    dim = isPaused
                )

                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = remaining,
                        color = if (isPaused) DiviseColors.TextDim else DiviseColors.Text,
                        fontSize = 30.sp,
                        fontWeight = FontWeight.SemiBold,
                        letterSpacing = 0.5.sp
                    )
                    if (isPaused) {
                        Text(
                            text = "PAUSED",
                            color = DiviseColors.Orange,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 0.6.sp
                        )
                    } else {
                        Text(
                            text = subRemaining,
                            color = DiviseColors.TextDim,
                            fontSize = 13.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                // Stop button
                IconButton(
                    onClick = onStop,
                    size = 36.dp,
                    color = if (isPaused) DiviseColors.Surface12 else DiviseColors.Red
                ) {
                    Box(
                        modifier = Modifier
                            .size(12.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(Color.White)
                    )
                }

                // Pause/Resume button
                IconButton(
                    onClick = onPauseResume,
                    size = 36.dp,
                    color = DiviseColors.Red
                ) {
                    if (isPaused) {
                        // Play icon
                        Text("▶", color = Color.White, fontSize = 12.sp)
                    } else {
                        // Pause icon
                        Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                            Box(
                                modifier = Modifier
                                    .width(4.dp)
                                    .height(12.dp)
                                    .clip(RoundedCornerShape(1.dp))
                                    .background(Color.White)
                            )
                            Box(
                                modifier = Modifier
                                    .width(4.dp)
                                    .height(12.dp)
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
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                modifier = Modifier.size(150.dp),
                contentAlignment = Alignment.Center
            ) {
                TimerRing(progress = 1f, size = 150.dp, dim = true)
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Done!", color = DiviseColors.Text, fontSize = 26.sp, fontWeight = FontWeight.SemiBold)
                    Text("0:00", color = DiviseColors.TextDim, fontSize = 12.sp)
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            PillButton(text = "Dismiss", onClick = onDismiss, color = DiviseColors.Red)
        }
    }
}
