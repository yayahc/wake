package dev.wake.app

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings

/**
 * The three grants that decide how strong the gate actually is.
 *
 * All of them are silent when missing: the alarm still rings, but it stops
 * taking over the screen, which reads as the app being broken rather than as a
 * permission problem. They are surfaced in the UI for that reason.
 */
object WakeAlarmPermissions {

    /**
     * The one that matters most.
     *
     * On Android 13+ a denied notification permission suppresses the ring
     * notification, and a full-screen intent attached to a notification that
     * cannot be posted never fires. The alarm still rings, because the service
     * runs either way, so the symptom is sound with no quiz and nothing in the
     * log to explain it.
     */
    fun areNotificationsEnabled(context: Context): Boolean =
        context.getSystemService(NotificationManager::class.java).areNotificationsEnabled()

    /**
     * Lets the ring notification take over a locked screen.
     *
     * Android 14 stopped granting this at install to anything that is not a
     * recognised clock or calling app, so a sideloaded build usually has to ask
     * for it. Without it the alert degrades to a heads-up notification and the
     * quiz never appears on its own.
     */
    fun canUseFullScreenIntent(context: Context): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            context.getSystemService(NotificationManager::class.java).canUseFullScreenIntent()
        } else {
            true
        }

    /**
     * Lets the ring service pull the quiz back after the user leaves.
     *
     * This is the permission that closes the Home button escape. Android
     * blocks activity starts from the background, and holding "display over
     * other apps" is the exemption that a foreground service alone does not
     * provide.
     */
    fun canDrawOverlays(context: Context): Boolean = Settings.canDrawOverlays(context)

    /** Exact alarms. Normally granted outright via USE_EXACT_ALARM. */
    fun canScheduleExact(context: Context): Boolean = WakeAlarmScheduler.canScheduleExact(context)

    fun status(context: Context): Map<String, Any> = mapOf(
        "notifications" to areNotificationsEnabled(context),
        "fullScreenIntent" to canUseFullScreenIntent(context),
        "drawOverlays" to canDrawOverlays(context),
        "exactAlarms" to canScheduleExact(context),
    )

    fun requestFullScreenIntent(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        launch(
            context,
            Intent(
                Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                Uri.parse("package:${context.packageName}"),
            ),
        )
    }

    fun requestDrawOverlays(context: Context) {
        launch(
            context,
            Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}"),
            ),
        )
    }

    fun requestExactAlarms(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        launch(
            context,
            Intent(
                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                Uri.parse("package:${context.packageName}"),
            ),
        )
    }

    /**
     * Xiaomi and friends gate background activity starts behind their own
     * toggles, on top of the standard permissions.
     *
     * On these builds SYSTEM_ALERT_WINDOW can read as granted while the launch
     * is still refused, so there is nothing to query: the only honest thing to
     * do is point the user at the screen and say what to turn on.
     */
    fun needsOemSetup(): Boolean = Build.MANUFACTURER.lowercase() in OEMS_WITH_EXTRA_GATES

    private val OEMS_WITH_EXTRA_GATES = setOf("xiaomi", "redmi", "poco")

    /**
     * Opens MIUI's per-app permission editor, which holds "Display pop-up
     * windows while running in the background" and "Show on Lock screen".
     * Falls back to the standard app info screen if that activity is missing.
     */
    fun openOemSettings(context: Context) {
        val miui = Intent().apply {
            component = android.content.ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.permissions.PermissionsEditorActivity",
            )
            putExtra("extra_pkgname", context.packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val opened = runCatching { context.startActivity(miui) }.isSuccess
        if (opened) return

        launch(
            context,
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${context.packageName}"),
            ),
        )
    }

    /** Settings screens vary by OEM; a missing one must not crash the app. */
    private fun launch(context: Context, intent: Intent) {
        runCatching {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }
}
