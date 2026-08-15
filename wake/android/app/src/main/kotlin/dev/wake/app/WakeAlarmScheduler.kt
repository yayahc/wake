package dev.wake.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Arms and disarms alarms through [AlarmManager].
 *
 * Uses `setAlarmClock` rather than `setExactAndAllowWhileIdle`: it is the only
 * variant fully exempt from Doze and app-standby, and it is the one the system
 * surfaces as a real alarm in the status bar. It also grants a short window in
 * which the receiver may start a foreground service from the background, which
 * the ring path depends on.
 */
object WakeAlarmScheduler {
    private const val TAG = "WakeAlarm"

    /** How long after a dismissal an unsolved alarm comes back. Matches iOS. */
    const val RETRY_INTERVAL_MS = 45_000L

    fun canScheduleExact(context: Context): Boolean {
        val manager = context.getSystemService(AlarmManager::class.java)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            manager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    /**
     * Arms a fresh alarm for [alarmId], superseding anything already pending
     * for the same Drift row.
     */
    fun arm(context: Context, alarmId: Int, message: String, ringAt: Long): WakeAlarmRecord {
        cancelAll(context, alarmId)
        val record = WakeAlarmRecord(alarmId = alarmId, message = message, ringAt = ringAt)
        WakeAlarmStore.upsert(context, record)
        schedule(context, record)
        return record
    }

    /**
     * Puts an unsolved alarm back [RETRY_INTERVAL_MS] from now.
     *
     * The hard gate means this is a fallback rather than the main path: it only
     * matters when the system killed the ring service, or the device rebooted
     * while an alarm was still owed.
     */
    fun rearm(context: Context, id: String) {
        val current = WakeAlarmStore.record(context, id) ?: return
        if (current.solved) return

        val updated = WakeAlarmStore.mutate(context, id) {
            it.copy(
                ringAt = System.currentTimeMillis() + RETRY_INTERVAL_MS,
                retryCount = it.retryCount + 1,
            )
        } ?: return

        schedule(context, updated)
        Log.i(TAG, "Re-armed ${updated.id} (retry ${updated.retryCount}).")
    }

    /** The one exit from the gate. */
    fun markQuizSolved(context: Context, id: String) {
        val record = WakeAlarmStore.record(context, id) ?: return
        cancel(context, record)
        WakeAlarmStore.remove(context, id)
        Log.i(TAG, "Quiz solved for $id; chain ended.")
    }

    fun cancelAll(context: Context, alarmId: Int) {
        WakeAlarmStore.all(context).filter { it.alarmId == alarmId }.forEach { cancel(context, it) }
        WakeAlarmStore.removeAll(context, alarmId)
    }

    /**
     * Re-arms anything that should still be owed but has no alarm pending.
     *
     * Runs on boot and on every app launch. A record survives a reboot but its
     * `AlarmManager` entry does not, so without this the chain would silently
     * die whenever the phone restarted overnight.
     */
    fun reconcile(context: Context) {
        WakeAlarmStore.unsolved(context).forEach { record ->
            if (pendingIntent(context, record, create = false) == null) {
                val ringAt = maxOf(record.ringAt, System.currentTimeMillis() + 1_000)
                schedule(context, record.copy(ringAt = ringAt).also { WakeAlarmStore.upsert(context, it) })
                Log.i(TAG, "Reconciled ${record.id}; alarm was missing.")
            }
        }
    }

    private fun schedule(context: Context, record: WakeAlarmRecord) {
        if (!canScheduleExact(context)) {
            Log.w(TAG, "Exact alarms not permitted; ${record.id} not armed.")
            return
        }

        val manager = context.getSystemService(AlarmManager::class.java)
        // AlarmManager fires immediately for a time in the past, which is the
        // right behaviour for a missed alarm, but nudge it forward so the
        // receiver is not racing the caller.
        val triggerAt = maxOf(record.ringAt, System.currentTimeMillis() + 1_000)
        val operation = pendingIntent(context, record, create = true)!!

        manager.setAlarmClock(
            AlarmManager.AlarmClockInfo(triggerAt, showAlarmIntent(context)),
            operation,
        )
        Log.i(TAG, "Armed ${record.id} for $triggerAt.")
    }

    private fun cancel(context: Context, record: WakeAlarmRecord) {
        pendingIntent(context, record, create = false)?.let {
            context.getSystemService(AlarmManager::class.java).cancel(it)
            it.cancel()
        }
    }

    /**
     * [create] false returns null when nothing is pending, which is how
     * [reconcile] detects a dropped alarm.
     */
    private fun pendingIntent(
        context: Context,
        record: WakeAlarmRecord,
        create: Boolean,
    ): PendingIntent? {
        val intent = Intent(context, WakeAlarmReceiver::class.java).apply {
            action = WakeAlarmReceiver.ACTION_RING
            putExtra(WakeAlarmReceiver.EXTRA_RECORD_ID, record.id)
            // Extras are not part of PendingIntent identity, so the record id
            // has to be in the data URI for per-alarm intents to stay distinct.
            data = android.net.Uri.parse("wake://alarm/${record.id}")
        }
        val flags = PendingIntent.FLAG_IMMUTABLE or
            if (create) PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_NO_CREATE
        return PendingIntent.getBroadcast(context, record.id.hashCode(), intent, flags)
    }

    /** Tapping the system alarm indicator opens the app. */
    private fun showAlarmIntent(context: Context): PendingIntent =
        PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
}
