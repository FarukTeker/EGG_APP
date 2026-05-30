package com.vestel.divise.watch

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.vestel.divise.watch.ui.theme.DiviseColors

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val vm: WatchViewModel = viewModel()
            androidx.wear.compose.material.MaterialTheme {
                androidx.compose.foundation.layout.Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(DiviseColors.WatchBg)
                ) {
                    WatchApp(viewModel = vm)
                }
            }
        }
    }
}
