package com.vestel.divise.watch.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.material.Text
import com.vestel.divise.watch.ui.components.PillButton
import com.vestel.divise.watch.ui.theme.DiviseColors

@Composable
fun SettingsScreen(onLogout: () -> Unit) {
    var haptic by remember { mutableStateOf(true) }
    var chime by remember { mutableStateOf(true) }
    var autoStart by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxSize()) {
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Settings",
            color = DiviseColors.Text,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Center
        )

        ScalingLazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            item {
                ToggleRow("Haptics", haptic) { haptic = it }
            }
            item {
                ToggleRow("Chime", chime) { chime = it }
            }
            item {
                ToggleRow("Auto-start", autoStart) { autoStart = it }
            }
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    PillButton(
                        text = "Log out",
                        onClick = onLogout,
                        color = DiviseColors.Surface12
                    )
                }
            }
            item {
                Text(
                    text = "Divisé · v1.0.0",
                    color = DiviseColors.TextMute,
                    fontSize = 9.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp)
                )
            }
        }
    }
}

@Composable
private fun ToggleRow(label: String, value: Boolean, onToggle: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(DiviseColors.SurfaceDim)
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, color = DiviseColors.Text, fontSize = 12.sp, fontWeight = FontWeight.Medium)

        Box(
            modifier = Modifier
                .width(30.dp)
                .height(18.dp)
                .clip(RoundedCornerShape(9.dp))
                .background(if (value) DiviseColors.Green else DiviseColors.Surface12)
                .clickable { onToggle(!value) }
        ) {
            Box(
                modifier = Modifier
                    .size(14.dp)
                    .offset(x = if (value) 14.dp else 2.dp, y = 2.dp)
                    .clip(CircleShape)
                    .background(androidx.compose.ui.graphics.Color.White)
            )
        }
    }
}
