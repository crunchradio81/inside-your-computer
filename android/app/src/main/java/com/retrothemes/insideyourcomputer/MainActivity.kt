package com.retrothemes.insideyourcomputer

import android.content.pm.ActivityInfo
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity : AppCompatActivity() {

    private lateinit var saverView: InsideComputerView
    private lateinit var stopButton: Button

    private val hideStopRunnable = Runnable {
        stopButton.animate()
            .alpha(0.12f)
            .setDuration(700L)
            .start()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.BLACK)
        }

        saverView = InsideComputerView(this)
        root.addView(
            saverView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        stopButton = Button(this).apply {
            text = getString(R.string.stop)
            isAllCaps = true
            alpha = 0.72f
            setTextColor(Color.WHITE)
            setBackgroundColor(0x88000000.toInt())
            minWidth = dp(88)
            minHeight = dp(48)
            setPadding(dp(16), dp(8), dp(16), dp(8))

            setOnClickListener {
                stopAndExit()
            }
        }

        val stopParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            topMargin = dp(18)
            marginEnd = dp(18)
        }
        root.addView(stopButton, stopParams)

        root.setOnClickListener {
            revealStopButton()
        }

        setContentView(root)
        enterImmersiveMode()
        revealStopButton()

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                stopAndExit()
            }
        })
    }

    override fun onResume() {
        super.onResume()
        enterImmersiveMode()
        saverView.start()
        revealStopButton()
    }

    override fun onPause() {
        saverView.stop()
        super.onPause()
    }

    override fun onDestroy() {
        saverView.release()
        stopButton.removeCallbacks(hideStopRunnable)
        super.onDestroy()
    }

    private fun stopAndExit() {
        stopButton.removeCallbacks(hideStopRunnable)
        saverView.stop()
        saverView.release()
        finish()
    }

    private fun revealStopButton() {
        stopButton.removeCallbacks(hideStopRunnable)
        stopButton.animate().cancel()
        stopButton.alpha = 0.72f
        stopButton.postDelayed(hideStopRunnable, 3200L)
    }

    private fun enterImmersiveMode() {
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.hide(
            WindowInsetsCompat.Type.statusBars() or
                WindowInsetsCompat.Type.navigationBars()
        )
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()
}
