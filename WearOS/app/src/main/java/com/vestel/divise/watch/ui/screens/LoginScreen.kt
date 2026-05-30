package com.vestel.divise.watch.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Text
import com.vestel.divise.watch.ui.components.PillButton
import com.vestel.divise.watch.ui.theme.DiviseColors

@Composable
fun LoginScreen(
    isLoading: Boolean,
    error: String?,
    onLogin: (String, String) -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 20.dp)
        ) {
            Text(
                text = "Log in",
                color = DiviseColors.Text,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(10.dp))

            BasicTextField(
                value = email,
                onValueChange = { email = it },
                singleLine = true,
                textStyle = TextStyle(color = DiviseColors.Text, fontSize = 12.sp),
                cursorBrush = SolidColor(DiviseColors.Red),
                decorationBox = { inner ->
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(30.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(DiviseColors.SurfaceDim)
                            .padding(horizontal = 8.dp),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        if (email.isEmpty()) {
                            Text("Email", color = DiviseColors.TextMute, fontSize = 12.sp)
                        }
                        inner()
                    }
                }
            )

            Spacer(modifier = Modifier.height(6.dp))

            BasicTextField(
                value = password,
                onValueChange = { password = it },
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                textStyle = TextStyle(color = DiviseColors.Text, fontSize = 12.sp),
                cursorBrush = SolidColor(DiviseColors.Red),
                decorationBox = { inner ->
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(30.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(DiviseColors.SurfaceDim)
                            .padding(horizontal = 8.dp),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        if (password.isEmpty()) {
                            Text("Password", color = DiviseColors.TextMute, fontSize = 12.sp)
                        }
                        inner()
                    }
                }
            )

            if (error != null) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(text = error, color = DiviseColors.Red, fontSize = 10.sp)
            }

            Spacer(modifier = Modifier.height(10.dp))

            PillButton(
                text = if (isLoading) "..." else "Log in",
                onClick = { if (!isLoading) onLogin(email, password) }
            )
        }
    }
}
