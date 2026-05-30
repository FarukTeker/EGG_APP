package com.vestel.divise.watch.ui.screens

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Text
import com.vestel.divise.watch.data.Doneness
import com.vestel.divise.watch.ui.components.PillButton
import com.vestel.divise.watch.ui.theme.DiviseColors

@Composable
fun HardnessPickerScreen(
    slotIndex: Int,
    totalSlots: Int,
    currentDoneness: Doneness,
    onSelect: (Doneness) -> Unit,
    onDone: () -> Unit
) {
    var selected by remember(currentDoneness) { mutableStateOf(currentDoneness) }
    val options = Doneness.entries
    val selectedIdx = options.indexOf(selected)

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "SLOT ${slotIndex + 1} OF $totalSlots",
                color = DiviseColors.TextDim,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.3.sp
            )

            Spacer(modifier = Modifier.height(10.dp))

            Box(
                modifier = Modifier
                    .width(160.dp)
                    .height(110.dp)
                    .border(1.5.dp, DiviseColors.Surface12, RoundedCornerShape(14.dp)),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                    modifier = Modifier.fillMaxSize()
                ) {
                    // Previous option
                    if (selectedIdx > 0) {
                        Text(
                            text = options[selectedIdx - 1].label,
                            color = DiviseColors.TextMute,
                            fontSize = 13.sp,
                            modifier = Modifier.clickable {
                                selected = options[selectedIdx - 1]
                                onSelect(selected)
                            }
                        )
                    } else {
                        Spacer(modifier = Modifier.height(16.dp))
                    }

                    Spacer(modifier = Modifier.height(4.dp))

                    // Current
                    Text(
                        text = selected.label,
                        color = DiviseColors.Text,
                        fontSize = 26.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = selected.minutes,
                        color = DiviseColors.TextDim,
                        fontSize = 11.sp
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    // Next option
                    if (selectedIdx < options.size - 1) {
                        Text(
                            text = options[selectedIdx + 1].label,
                            color = DiviseColors.TextMute,
                            fontSize = 13.sp,
                            modifier = Modifier.clickable {
                                selected = options[selectedIdx + 1]
                                onSelect(selected)
                            }
                        )
                    } else {
                        Spacer(modifier = Modifier.height(16.dp))
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            PillButton(
                text = if (slotIndex == totalSlots - 1) "Done" else "Next",
                onClick = {
                    onSelect(selected)
                    onDone()
                },
                color = DiviseColors.Surface12
            )
        }
    }
}

@Composable
fun SummaryScreen(
    slots: List<Pair<Doneness, Boolean>>,
    totalTime: String,
    onStart: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "READY TO COOK",
                color = DiviseColors.TextDim,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.3.sp
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                slots.filter { it.second }.forEach { (doneness, _) ->
                    com.vestel.divise.watch.ui.components.CookerSlot(
                        doneness = doneness,
                        active = true
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            Row {
                Text("Total ", color = DiviseColors.TextDim, fontSize = 13.sp)
                Text(totalTime, color = DiviseColors.Text, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
            }

            Spacer(modifier = Modifier.height(10.dp))

            PillButton(text = "Start", onClick = onStart)
        }
    }
}
