package dev.wake.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Fires when an armed alarm comes due and hands off to [WakeAlarmService].
 *
 * Nothing here touches Flutter. The whole point of dropping
 * android_alarm_manager_plus was that the ring path no longer waits on a
 * background Dart isolate booting, which is the step that fails under memory
 * pressure and after a cold boot.
 */
class WakeAlarmReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_RING = "dev.wake.app.action.RING"
        const val EXTRA_RECORD_ID = "dev.wake.app.extra.RECORD_ID"
        private const val TAG = "WakeAlarm"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_RING) return
        val recordId = intent.getStringExtra(EXTRA_RECORD_ID) ?: return

        val record = WakeAlarmStore.record(context, recordId)
        if (record == null || record.solved) {
            Log.i(TAG, "Ignoring $recordId: already solved or unknown.")
            return
        }

        // setAlarmClock grants a background-start exemption, so starting a
        // foreground service from here is allowed even on Android 12+.
        WakeAlarmService.start(context, recordId)
    }
}

/**
 * Restores alarms after the device reboots or the app is updated.
 *
 * `AlarmManager` forgets everything across a reboot, but [WakeAlarmStore] does
 * not, so reconciliation is enough to bring the chain back.
 */
class WakeAlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            -> WakeAlarmScheduler.reconcile(context)
        }
    }
}
