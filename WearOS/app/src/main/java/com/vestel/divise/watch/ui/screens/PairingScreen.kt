package com.vestel.divise.watch.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.background
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Text
import com.vestel.divise.watch.ui.components.PillButton
import com.vestel.divise.watch.ui.theme.DiviseColors

@Composable
fun PairingScreen(isPairing: Boolean, onStartPairing: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        if (isPairing) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(
                    modifier = Modifier.size(100.dp),
                    contentAlignment = Alignment.Center
                ) {
                    repeat(3) { i ->
                        val infiniteTransition = rememberInfiniteTransition(label = "pulse$i")
                        val scale by infiniteTransition.animateFloat(
                            initialValue = 0.8f,
                            targetValue = 2f,
                            animationSpec = infiniteRepeatable(
                                animation = tween(1800, easing = FastOutSlowInEasing),
                                repeatMode = RepeatMode.Restart,
                                initialStartOffset = StartOffset(i * 600)
                            ),
                            label = "scale$i"
                        )
                        val alpha by infiniteTransition.animateFloat(
                            initialValue = 0.6f,
                            targetValue = 0f,
                            animationSpec = infiniteRepeatable(
                                animation = tween(1800, easing = FastOutSlowInEasing),
                                repeatMode = RepeatMode.Restart,
                                initialStartOffset = StartOffset(i * 600)
                            ),
                            label = "alpha$i"
                        )
                        Box(
                            modifier = Modifier
                                .size(60.dp)
                                .scale(scale)
                                .graphicsLayer { this.alpha = alpha }
                                .border(1.5.dp, DiviseColors.Red, CircleShape)
                        )
                    }
                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .clip(CircleShape)
                            .background(DiviseColors.Red),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("?", color = DiviseColors.Text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))
                Text("Searching...", color = DiviseColors.Text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                Text("Looking for Divisé", color = DiviseColors.TextDim, fontSize = 11.sp)
            }
        } else {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("No device", color = DiviseColors.Text, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.height(4.dp))
                Text("Pair your Divisé cooker", color = DiviseColors.TextDim, fontSize = 12.sp)
                Spacer(modifier = Modifier.height(16.dp))
                PillButton(text = "Search", onClick = onStartPairing)
            }
        }
    }
}

@Composable
fun ConnectedScreen(deviceName: String, onContinue: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(DiviseColors.Green),
                contentAlignment = Alignment.Center
            ) {
                Text("✓", color = DiviseColors.Text, fontSize = 28.sp, fontWeight = FontWeight.Bold)
            }
            Spacer(modifier = Modifier.height(14.dp))
            Text("Connected", color = DiviseColors.Text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(4.dp))
            Text("Divisé · $deviceName", color = DiviseColors.TextDim, fontSize = 12.sp)
            Spacer(modifier = Modifier.height(16.dp))
            PillButton(text = "Continue", onClick = onContinue, color = DiviseColors.Green)
        }
    }
}
