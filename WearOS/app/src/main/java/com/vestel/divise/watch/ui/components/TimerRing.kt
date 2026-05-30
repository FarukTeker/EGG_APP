package com.vestel.divise.watch.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.vestel.divise.watch.ui.theme.DiviseColors
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun TimerRing(
    progress: Float,
    modifier: Modifier = Modifier,
    size: Dp = 150.dp,
    strokeWidth: Dp = 6.dp,
    dim: Boolean = false
) {
    val trackColor = DiviseColors.RingTrack
    val startColor = if (dim) DiviseColors.RedDim else DiviseColors.Red
    val endColor = if (dim) DiviseColors.Orange.copy(alpha = 0.5f) else DiviseColors.Orange

    Canvas(modifier = modifier.size(size)) {
        val stroke = strokeWidth.toPx()
        val radius = (this.size.minDimension - stroke) / 2f
        val center = Offset(this.size.width / 2f, this.size.height / 2f)

        // Track
        drawCircle(
            color = trackColor,
            radius = radius,
            center = center,
            style = Stroke(width = stroke)
        )

        // Progress arc
        if (progress > 0.005f) {
            val sweepAngle = 360f * progress
            drawArc(
                brush = Brush.sweepGradient(
                    colors = listOf(startColor, endColor, startColor),
                    center = center
                ),
                startAngle = -90f,
                sweepAngle = sweepAngle,
                useCenter = false,
                style = Stroke(width = stroke, cap = StrokeCap.Round)
            )

            // Start dot
            val startAngleRad = -PI / 2
            drawCircle(
                color = startColor,
                radius = stroke / 1.4f,
                center = Offset(
                    center.x + radius * cos(startAngleRad).toFloat(),
                    center.y + radius * sin(startAngleRad).toFloat()
                )
            )

            // End dot
            val endAngleRad = startAngleRad + (sweepAngle * PI / 180.0)
            drawCircle(
                color = endColor,
                radius = stroke / 1.4f,
                center = Offset(
                    center.x + radius * cos(endAngleRad).toFloat(),
                    center.y + radius * sin(endAngleRad).toFloat()
                )
            )
        }
    }
}
