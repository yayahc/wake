package dev.wake.app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    companion object {
        const val EXTRA_RECORD_ID = "dev.wake.app.extra.QUIZ_RECORD_ID"

        /**
         * The activity the ringing notification's full-screen intent points at.
         *
         * `NEW_TASK` plus `SINGLE_TOP` means a repeat fire reuses the running
         * activity through [onNewIntent] instead of stacking quiz screens.
         */
        fun quizIntent(context: Context, recordId: String): Intent =
            Intent(context, MainActivity::class.java).apply {
                putExtra(EXTRA_RECORD_ID, recordId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent.hasExtra(EXTRA_RECORD_ID)) showOverLockScreen()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.hasExtra(EXTRA_RECORD_ID)) showOverLockScreen()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // App-local plugin, so it is not in the generated registrant.
        flutterEngine.plugins.add(WakeAlarmPlugin())
    }

    /**
     * Puts the quiz in front of the lock screen and lights the display.
     *
     * Deliberately does not call `requestDismissKeyguard`: the quiz works fine
     * over a locked device, and dismissing would force a PIN entry before the
     * user could even see the question.
     */
    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
