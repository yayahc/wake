package dev.wake.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * Keeps an alarm ringing until its quiz is solved.
 *
 * This is the half of the gate iOS cannot have. The service owns the sound and
 * the wake lock, so leaving the quiz screen does not stop anything: the user
 * can background the app, but the alarm keeps playing and the full-screen
 * intent keeps pulling the quiz back to the front.
 *
 * The one escape Android still allows is Home followed by ignoring the sound.
 * Closing that would need SYSTEM_ALERT_WINDOW to draw over other apps, which
 * is a heavyweight permission and is deliberately not requested here.
 */
class WakeAlarmService : Service() {

    companion object {
        private const val TAG = "WakeAlarm"
        private const val CHANNEL_ID = "wake_alarm_ring"
        private const val NOTIFICATION_ID = 0x3A1A

        private const val EXTRA_RECORD_ID = "record_id"

        /**
         * How often the quiz is hauled back in front. Short enough that going
         * Home is an interruption rather than an escape, long enough not to
         * fight the user's every touch.
         */
        private const val REASSERT_INTERVAL_MS = 5_000L

        /** Alarm volume is forced to at least this fraction of the maximum. */
        private const val MIN_VOLUME_FRACTION = 0.6

        /** The record currently ringing, if any. Read by the plugin. */
        @Volatile
        var ringingRecordId: String? = null
            private set

        fun start(context: Context, recordId: String) {
            val intent = Intent(context, WakeAlarmService::class.java)
                .putExtra(EXTRA_RECORD_ID, recordId)
            context.startForegroundService(intent)
        }

        /**
         * Set just before the service is torn down on purpose, so [onDestroy]
         * can tell a solved alarm from one the system killed.
         */
        @Volatile
        private var solvedRecordId: String? = null

        /** Stops the alarm for good. Only the solved quiz path may call this. */
        fun stopSolved(context: Context, recordId: String) {
            solvedRecordId = recordId
            context.stopService(Intent(context, WakeAlarmService::class.java))
        }
    }

    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private var recordId: String? = null

    private val reassert = object : Runnable {
        override fun run() {
            recordId?.let { pullQuizToFront(it) }
            handler.postDelayed(this, REASSERT_INTERVAL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val id = intent?.getStringExtra(EXTRA_RECORD_ID)
        val record = id?.let { WakeAlarmStore.record(this, it) }

        if (record == null || record.solved) {
            stopSelf()
            return START_NOT_STICKY
        }

        // A second alarm arriving while one is already ringing just keeps the
        // first one going; the store still owes both quizzes. Every
        // startForegroundService call must be answered with startForeground
        // regardless, or the system kills the process for missing the window.
        if (recordId != null && recordId != record.id) {
            Log.i(TAG, "Already ringing $recordId; queuing ${record.id} for later.")
            startForegroundWithNotification(recordId!!)
            return START_STICKY
        }

        recordId = record.id
        ringingRecordId = record.id

        // A quiz is owed from this moment, not from when the alarm was armed.
        // Must happen before anything below reads the store.
        WakeAlarmStore.mutate(this, record.id) { it.copy(fired = true) }

        startForegroundWithNotification(record.id)
        acquireWakeLock()
        startRinging()
        pullQuizToFront(record.id)
        handler.removeCallbacks(reassert)
        handler.postDelayed(reassert, REASSERT_INTERVAL_MS)

        // Covers the one case the full-screen intent does not: the app is
        // already open, so there is no resume for Dart to react to.
        WakeAlarmPlugin.notifyRinging(record.id)

        // START_STICKY so a low-memory kill brings the service back rather
        // than silently ending the alarm.
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(reassert)
        stopRinging()
        releaseWakeLock()

        val id = recordId
        ringingRecordId = null
        recordId = null

        // Killed before the quiz was answered: put the alarm back rather than
        // letting a process death count as a skip.
        if (id != null && solvedRecordId != id) {
            WakeAlarmScheduler.rearm(this, id)
        }
        if (solvedRecordId == id) solvedRecordId = null
        super.onDestroy()
    }

    // MARK: - Notification

    private fun startForegroundWithNotification(recordId: String) {
        createChannel()
        val notification = buildNotification(recordId)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun notify(recordId: String) {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, buildNotification(recordId))
    }

    /**
     * Gets the quiz in front of the user, by whichever route is available.
     *
     * Neither route is sufficient alone. The full-screen intent only takes
     * over the screen while the device is locked, is not granted by default on
     * Android 14+, and dies silently if notifications are denied. It also only
     * fires on the first post, so on repeat calls this is the activity start
     * doing the work. That in turn needs the overlay permission, since Android
     * blocks background activity starts and a foreground service is not an
     * exemption. With neither grant the notification is all that is left.
     */
    private fun pullQuizToFront(recordId: String) {
        notify(recordId)

        if (!WakeAlarmPermissions.canDrawOverlays(this)) return
        runCatching { startActivity(MainActivity.quizIntent(this, recordId)) }
            .onFailure { Log.w(TAG, "Could not bring the quiz forward", it) }
    }

    private fun createChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Alarms",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Ringing alarms that need a quiz answer"
            // The service owns the sound, so the channel must stay silent or
            // the ringtone plays twice.
            setSound(null, null)
            enableVibration(false)
            setBypassDnd(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun buildNotification(recordId: String): Notification {
        val record = WakeAlarmStore.record(this, recordId)
        val fullScreen = PendingIntent.getActivity(
            this,
            recordId.hashCode(),
            MainActivity.quizIntent(this, recordId),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle(record?.message?.takeIf { it.isNotBlank() } ?: "Wake up")
            .setContentText("Solve the quiz to stop the alarm")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(fullScreen)
            // `true` marks it high priority, which is what lets it take over
            // the screen while the device is locked.
            .setFullScreenIntent(fullScreen, true)
            .build()
    }

    // MARK: - Sound and vibration

    private fun startRinging() {
        // START_STICKY can redeliver the same start; do not stack ringtones.
        if (player != null) return
        raiseAlarmVolume()

        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

        player = runCatching {
            MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        // USAGE_ALARM plays on the alarm stream, which ignores
                        // the silent switch and most Do Not Disturb setups.
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(this@WakeAlarmService, uri)
                isLooping = true
                prepare()
                start()
            }
        }.onFailure { Log.e(TAG, "Could not start ringtone", it) }.getOrNull()

        vibrator = vibratorService()?.also {
            val pattern = longArrayOf(0, 800, 600)
            it.vibrate(VibrationEffect.createWaveform(pattern, 0))
        }
    }

    private fun stopRinging() {
        player?.runCatching { stop(); release() }
        player = null
        vibrator?.cancel()
        vibrator = null
    }

    /**
     * An alarm muted by the alarm slider wakes nobody. Raised rather than
     * maxed, so it is still loud without being punishing.
     */
    private fun raiseAlarmVolume() {
        val audio = getSystemService(AudioManager::class.java)
        val max = audio.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        val target = (max * MIN_VOLUME_FRACTION).toInt().coerceAtLeast(1)
        if (audio.getStreamVolume(AudioManager.STREAM_ALARM) < target) {
            runCatching { audio.setStreamVolume(AudioManager.STREAM_ALARM, target, 0) }
                .onFailure { Log.w(TAG, "Could not raise alarm volume", it) }
        }
    }

    private fun vibratorService(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java)
        }

    // MARK: - Wake lock

    private fun acquireWakeLock() {
        val power = getSystemService(PowerManager::class.java)
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "wake:alarm").apply {
            setReferenceCounted(false)
            // Bounded so a bug cannot hold the CPU awake indefinitely.
            acquire(30 * 60 * 1000L)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
    }
}
