package com.vestel.divise.watch.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.vestel.divise.watch.ui.theme.DiviseColors
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * One coloured band of the cook schedule, ordered from cook start (t=0).
 * [fraction] is this band's share of the total cook time; [color] encodes the
 * doneness of the egg(s) that finish at the end of the band.
 */
data class TimerSegment(val fraction: Float, val color: Color)

@Composable
fun TimerRing(
    progress: Float,            // remaining fraction of total cook time, 1f -> 0f
    modifier: Modifier = Modifier,
    size: Dp? = null,           // null => take size from [modifier] (e.g. fillMaxSize)
    strokeWidth: Dp = 6.dp,
    dim: Boolean = false,
    segments: List<TimerSegment> = emptyList()
) {
    val trackColor = DiviseColors.RingTrack
    val sizedModifier = if (size != null) modifier.size(size) else modifier

    Canvas(modifier = sizedModifier) {
        val stroke = strokeWidth.toPx()
        val radius = (this.size.minDimension - stroke) / 2f
        val center = Offset(this.size.width / 2f, this.size.height / 2f)
        val topDeg = -90f // 12 o'clock

        // Arcs must ride on the SAME oval as the track circle, otherwise they
        // sit ~stroke/2 outside it. drawArc defaults to the full-canvas oval, so
        // pin it to the track's bounds explicitly.
        val arcTopLeft = Offset(center.x - radius, center.y - radius)
        val arcSize = Size(radius * 2f, radius * 2f)

        fun pointAt(fraction: Float): Offset {
            val rad = (topDeg + 360f * fraction) * (PI.toFloat() / 180f)
            return Offset(
                center.x + radius * cos(rad),
                center.y + radius * sin(rad)
            )
        }

        // Track
        drawCircle(
            color = trackColor,
            radius = radius,
            center = center,
            style = Stroke(width = stroke)
        )

        val elapsed = (1f - progress).coerceIn(0f, 1f)

        if (segments.isNotEmpty()) {
            // Draw each schedule band, but only the part that is still remaining
            // (i.e. past the elapsed boundary). Consumed time shows only the dim
            // track, so the colour/track boundary sweeps CLOCKWISE as eggs cook.
            var start = 0f
            for (seg in segments) {
                val end = (start + seg.fraction).coerceAtMost(1f)
                val visibleStart = maxOf(start, elapsed)
                if (end > visibleStart) {
                    drawArc(
                        color = if (dim) seg.color.copy(alpha = 0.4f) else seg.color,
                        startAngle = topDeg + 360f * visibleStart,
                        sweepAngle = 360f * (end - visibleStart),
                        useCenter = false,
                        topLeft = arcTopLeft,
                        size = arcSize,
                        // Butt caps keep crisp boundaries between egg colours.
                        style = Stroke(width = stroke, cap = StrokeCap.Butt)
                    )
                }
                start = end
            }

            // Colour-transition dots: a dot at the END of each band, coloured by
            // the band that ends there (blue dot = end of the blue/Soft part).
            // Only drawn where the boundary is still on the remaining arc.
            var acc = 0f
            for (seg in segments) {
                acc = (acc + seg.fraction).coerceAtMost(1f)
                if (acc >= elapsed - 0.0001f) {
                    drawCircle(
                        color = if (dim) seg.color.copy(alpha = 0.4f) else seg.color,
                        radius = stroke / 1.4f,
                        center = pointAt(acc)
                    )
                }
            }

            // Current-time marker (white) sweeping clockwise.
            if (progress in 0.001f..0.999f) {
                drawCircle(
                    color = Color.White,
                    radius = stroke / 1.4f,
                    center = pointAt(elapsed)
                )
            }
        } else {
            // Fallback: single gradient arc (start / done screens, no per-egg data).
            val startColor = if (dim) DiviseColors.RedDim else DiviseColors.Red
            val endColor = if (dim) DiviseColors.Orange.copy(alpha = 0.5f) else DiviseColors.Orange
            if (progress > 0.005f) {
                drawArc(
                    brush = Brush.sweepGradient(
                        colors = listOf(startColor, endColor, startColor),
                        center = center
                    ),
                    startAngle = topDeg,
                    sweepAngle = 360f * progress,
                    useCenter = false,
                    topLeft = arcTopLeft,
                    size = arcSize,
                    style = Stroke(width = stroke, cap = StrokeCap.Round)
                )
            }
        }
    }
}
