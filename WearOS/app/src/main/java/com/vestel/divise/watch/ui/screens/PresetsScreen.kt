package com.vestel.divise.watch.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import com.vestel.divise.watch.data.Doneness
import com.vestel.divise.watch.data.PresetResponse
import com.vestel.divise.watch.ui.components.MiniSlotIndicator
import com.vestel.divise.watch.ui.components.PillButton
import com.vestel.divise.watch.ui.theme.DiviseColors

@Composable
fun PresetsScreen(
    presets: List<PresetResponse>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    onUse: () -> Unit,
    onCustom: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize()) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Presets",
                color = DiviseColors.Text,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.fillMaxWidth(),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            ScalingLazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
                verticalArrangement = Arrangement.spacedBy(3.dp)
            ) {
                itemsIndexed(presets) { index, preset ->
                    val isSelected = index == selectedIndex
                    PresetRow(
                        preset = preset,
                        isSelected = isSelected,
                        onClick = { onSelect(index) }
                    )
                }
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable(onClick = onCustom)
                            .padding(vertical = 4.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("+ Custom...", color = DiviseColors.TextDim, fontSize = 10.sp)
                    }
                }
            }

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 4.dp),
                contentAlignment = Alignment.Center
            ) {
                PillButton(text = "Use", onClick = onUse)
            }
        }
    }
}

@Composable
private fun PresetRow(
    preset: PresetResponse,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val bgColor = if (isSelected) DiviseColors.Red.copy(alpha = 0.18f) else DiviseColors.SurfaceDim
    val borderColor = if (isSelected) DiviseColors.Red else android.graphics.Color.TRANSPARENT.let {
        androidx.compose.ui.graphics.Color.Transparent
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(9.dp))
            .background(bgColor)
            .border(1.5.dp, borderColor, RoundedCornerShape(9.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            preset.donenessLevels.filter { it.isNotBlank() }.forEach { level ->
                MiniSlotIndicator(Doneness.fromString(level))
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = preset.name,
                color = DiviseColors.Text,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            val sub = preset.donenessLevels.filter { it.isNotBlank() }.joinToString(" · ") {
                it.first().toString()
            }
            Text(text = sub, color = DiviseColors.TextDim, fontSize = 9.sp)
        }

        val maxDoneness = preset.donenessLevels.filter { it.isNotBlank() }
            .maxOfOrNull { Doneness.fromString(it).seconds } ?: 0
        val timeStr = "${maxDoneness / 60}:%02d".format(maxDoneness % 60)
        Text(
            text = timeStr,
            color = if (isSelected) DiviseColors.Red else DiviseColors.TextDim,
            fontSize = 10.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}
