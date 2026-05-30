package com.vestel.divise.watch.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.itemsIndexed
import androidx.wear.compose.material.Text
import com.vestel.divise.watch.data.CookSessionResponse
import com.vestel.divise.watch.data.Doneness
import com.vestel.divise.watch.ui.components.MiniSlotIndicator
import com.vestel.divise.watch.ui.theme.DiviseColors

@Composable
fun HistoryScreen(sessions: List<CookSessionResponse>) {
    Column(modifier = Modifier.fillMaxSize()) {
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Recent",
            color = DiviseColors.Text,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.fillMaxWidth(),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )

        if (sessions.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text("No history yet", color = DiviseColors.TextDim, fontSize = 12.sp)
            }
        } else {
            ScalingLazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                itemsIndexed(sessions.take(10)) { index, session ->
                    HistoryRow(session = session, isFirst = index == 0)
                }
            }
        }
    }
}

@Composable
private fun HistoryRow(session: CookSessionResponse, isFirst: Boolean) {
    val bgColor = if (isFirst) DiviseColors.Red.copy(alpha = 0.15f) else DiviseColors.SurfaceDim
    val statusDot = when (session.status) {
        "completed" -> DiviseColors.Green
        "cancelled" -> DiviseColors.Red
        else -> DiviseColors.Orange
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(bgColor)
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            session.donenessLevels.filter { it.isNotBlank() }.forEach { level ->
                MiniSlotIndicator(Doneness.fromString(level))
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = session.presetName ?: session.mode.replaceFirstChar { it.uppercase() },
                color = DiviseColors.Text,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = session.status.replaceFirstChar { it.uppercase() },
                color = statusDot,
                fontSize = 9.sp
            )
        }
    }
}
