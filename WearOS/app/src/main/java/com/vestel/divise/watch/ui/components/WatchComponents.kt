package com.vestel.divise.watch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Text
import com.vestel.divise.watch.data.Doneness
import com.vestel.divise.watch.ui.theme.DiviseColors

@Composable
fun PillButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    color: Color = DiviseColors.Red
) {
    Box(
        modifier = modifier
            .height(36.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(color)
            .clickable(onClick = onClick)
            .padding(horizontal = 22.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = Color.White,
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
fun IconButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    color: Color = DiviseColors.Red,
    size: Dp = 40.dp,
    content: @Composable () -> Unit
) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(color)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}

@Composable
fun CookerSlot(
    doneness: Doneness,
    active: Boolean,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    val borderColor = if (!active) DiviseColors.SurfaceDim
    else when (doneness) {
        Doneness.Hard -> DiviseColors.Red
        Doneness.Medium -> DiviseColors.Orange
        Doneness.Soft -> DiviseColors.Yellow
    }

    // Egg dots sit on a neutral surface, so they track the theme's text color
    // (white in dark, near-black in light) rather than a hardcoded white.
    val eggColor = if (active) DiviseColors.Text.copy(alpha = 0.78f) else DiviseColors.Text.copy(alpha = 0.1f)

    Column(
        modifier = modifier
            .width(40.dp)
            .height(70.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(DiviseColors.SurfaceDim)
            .border(2.dp, borderColor, RoundedCornerShape(8.dp))
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier),
        verticalArrangement = Arrangement.SpaceEvenly,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .size(18.dp)
                .clip(CircleShape)
                .background(eggColor)
        )
        Box(
            modifier = Modifier
                .size(18.dp)
                .clip(CircleShape)
                .background(eggColor)
        )
    }
}

@Composable
fun ScreenTitle(text: String) {
    Text(
        text = text,
        color = DiviseColors.TextDim,
        fontSize = 11.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = 0.3.sp,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth()
    )
}

@Composable
fun MiniSlotIndicator(doneness: Doneness) {
    val color = when (doneness) {
        Doneness.Hard -> DiviseColors.Red
        Doneness.Medium -> DiviseColors.Orange
        Doneness.Soft -> DiviseColors.Yellow
    }
    Box(
        modifier = Modifier
            .width(8.dp)
            .height(14.dp)
            .clip(RoundedCornerShape(2.dp))
            .border(1.5.dp, color, RoundedCornerShape(2.dp))
    )
}
